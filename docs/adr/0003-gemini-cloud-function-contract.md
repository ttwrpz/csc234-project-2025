# ADR-0003 — `analyzeMoodText` Cloud Function Contract

**Status:** Accepted
**Date:** 2026-04-29
**Deciders:** orchestrator + architect
**Related:** ADR-0001 (repo structure); ADR-0004 (Drift offline-first); CLAUDE.md (locked stack: Gemini via Cloud Functions proxy, never direct from app)

## Context

Sprint 3 introduces AI-assisted mood logging (US-Lin-2). The Flutter client must never call Gemini directly — the API key would ship in app bundles, request shaping would scatter across platforms, and there would be no enforcement seam for rate limits or PII handling. CLAUDE.md mandates a Cloud Functions proxy. This ADR specifies the wire contract, error taxonomy, prompt template, validation pipeline, logging schema, and test plan that govern that proxy.

The function is on the critical path of the Sprint 3 demo (the AI suggestion pill) but it is *not* on the critical path of saving a mood entry — manual mood selection must always work, and a Gemini outage cannot block the user. This shapes both the contract (result-typed responses, explicit error variants) and the UX requirements downstream.

The mood enum has six values: `happy, calm, okay, sad, angry, anxious` (apps/mobile/lib/features/mood/domain/entities/mood_type.dart:3-9). The Sprint 3 kickoff prompt mistakenly says "seven" — the contract here uses six.

## Decision

### Transport and runtime

- HTTPS-callable Cloud Function v2 (`firebase-functions/v2`, `onCall`). Region: `asia-southeast1` (matches existing Firestore project, lowest latency for KMUTT users).
- `enforceAppCheck: true` (matches `analyzePatterns`). Sprint 3 originally shipped with `enforceAppCheck: false` and Firebase Auth + per-user rate limit as the only defences; the v1.0.1 patch enables enforcement to bring `analyzeMoodText` to parity with `analyzePatterns`. Clients call via `FirebaseFunctions.instanceFor(region: 'asia-southeast1')` which attaches App Check tokens automatically when the SDK is initialised; the wire contract is unchanged.
- Runtime: Node 20, ESM (`"type": "module"`), `timeoutSeconds: 30`, `memory: '256MiB'`.
- Model: `gemini-2.5-flash` via `@google/genai` (migrated from the deprecated `@google/generative-ai` in v1.0.1; the call shape changed from `model.generateContent(req, opts)` to `ai.models.generateContent({ model, contents, config })` but the wire contract above is unchanged). Generation config: `temperature: 0.2`, `topP: 0.9`, `maxOutputTokens: 200`, `responseMimeType: 'application/json'`, `responseSchema` enum-constrained to the six moods.

### Secret handling

`defineSecret('GEMINI_API_KEY')` from `firebase-functions/params`. The handler reads `.value()` lazily inside the function so the secret binding is honoured at runtime. **Never** `functions.config()` (deprecated and committed to source). **Never** `process.env.GEMINI_API_KEY` direct read (skips the binding ceremony). The pre-commit secret-scan hook (`.claude/hooks/settings.json`) blocks accidental key commits; the test plan adds a sentinel canary check.

### Wire format

```ts
// Request
interface AnalyzeMoodTextRequest {
  text: string;        // 1..500 chars after trim; matches MoodEntry.text validation
  requestId: string;   // client-generated UUID v4 (idempotency hint, log correlation)
  locale?: string;     // ISO-639-1, e.g. "th", "en"
  v: 1;                // schema version
}

// Response — discriminated union
type AnalyzeMoodTextResponse = AnalyzeMoodTextSuccess | AnalyzeMoodTextError;

interface AnalyzeMoodTextSuccess {
  ok: true; v: 1; requestId: string;
  mood: 'happy' | 'calm' | 'okay' | 'sad' | 'angry' | 'anxious';
  confidence: number;                                     // [0.0, 1.0] — clamped
  alternative: { mood: ...; confidence: number } | null;  // for override UX
  rationale: string;                                      // <=80 chars; theme-level, no PII echo
  flag?: 'self_harm_safety';                              // S3: hide pill; S4: gentle banner
  latencyMs: number;
  modelVersion: string;                                   // 'gemini-2.5-flash'
}

interface AnalyzeMoodTextError {
  ok: false; v: 1; requestId: string;
  code: 'unauthenticated' | 'invalid_input' | 'rate_limited'
      | 'gemini_unavailable' | 'parse_error' | 'internal';
  message: string;                                        // user-safe, no stack/PII
  retryAfterSec?: number;                                 // only when code==='rate_limited'
}
```

Result-shaped responses (rather than throwing `HttpsError` for every error) map cleanly onto Dart's `Result<AiSuggestion, AiAnalysisFailure>` pattern. The exception is `unauthenticated` — that *does* throw `HttpsError('unauthenticated')` because it must short-circuit before we trust any payload. The Dart datasource maps `FirebaseFunctionsException.code === 'unauthenticated'` to `AiAnalysisFailure.unauthenticated`; everything else comes back as `{ok: false, code}`.

### Validation order (short-circuit; first failure wins)

1. `request.auth.uid` present → else throw `HttpsError('unauthenticated')`.
2. Zod-parse `request.data` → else `{ok: false, code: 'invalid_input'}`.
3. Trim + length cap (1..500) → else `invalid_input`.
4. `consumeToken(uid)` Firestore transaction → else `rate_limited` with `retryAfterSec`.
5. Gemini call wrapped in 5s `AbortController` → on abort/5xx → `gemini_unavailable`.
6. Zod-parse Gemini response (enum-constrained); clamp `confidence` to [0,1]; if mood ∉ enum → `parse_error`.
7. Emit one structured log line.
8. Return success.

The rate-limit token is consumed *before* the Gemini call so a Gemini outage cannot DoS the project's Gemini quota by amplifying retries.

### Rate limit

10 requests / minute / uid. Firestore doc `rateLimits/{uid}` shape:

```
{ windowStartMs: number, count: number, expireAt: Timestamp }
```

TTL on `expireAt` keeps storage growth bounded by active-user count, not lifetime requests. The transaction:

```
function consumeToken(tx, uid, nowMs):
  ref = db.doc(`rateLimits/${uid}`)
  snap = tx.get(ref)
  if not snap.exists or nowMs - data.windowStartMs >= 60_000:
    tx.set(ref, {windowStartMs: nowMs, count: 1, expireAt: nowMs + 60_000})
    return {allowed: true, retryAfterSec: 0}
  if data.count >= 10:
    return {allowed: false, retryAfterSec: ceil((data.windowStartMs + 60_000 - nowMs) / 1000)}
  tx.update(ref, {count: data.count + 1})
  return {allowed: true, retryAfterSec: 0}
```

Concurrency-safe: Firestore `runTransaction` retries on contention. Two simultaneous calls cannot both observe `count===9` and both write `count=10`.

### Gemini system prompt (canonical)

```
You are MoodBloom's mood classifier. You receive one short user-authored
journal entry (Thai or English) and return a single JSON object describing
which of MoodBloom's six mood categories best fits the entry.

ALLOWED MOODS — return EXACTLY one of these strings, lowercase:
  happy, calm, okay, sad, angry, anxious

RULES
1. Use ONLY the six mood strings above. No synonyms, plurals, capitalisation,
   or translations.
2. Return JSON: { "mood", "confidence" (0..1), "alternative" | null,
   "rationale" (<=80 chars, no PII echo), "flag" | null }.
3. SAFETY: explicit self-harm or suicidal intent → flag="self_harm_safety",
   mood="okay", confidence=0.2. Do NOT moralise. Do NOT include hotlines.
   The app handles that downstream.
4. EMPTY/GIBBERISH: mood="okay", confidence<=0.4, alternative=null, flag=null.
5. RATIONALE: refer to themes ("themes of loss and fatigue"), never quote
   the user's input. English only — UI localises.

ONE-SHOT EXAMPLE
Input:  "I aced the presentation today and the team cheered. Feeling proud."
Output: {"mood":"happy","confidence":0.92,
         "alternative":{"mood":"calm","confidence":0.31},
         "rationale":"Achievement and social validation indicate happy.",
         "flag":null}
```

### Logging schema (one structured log line per call)

Allowed fields: `event, requestId, uid, outcome, textLen, locale, model, latencyTotalMs, latencyGeminiMs, promptTokens, completionTokens, classification.{mood, confidence, safetyFlag}, rateLimit.{remaining, retryAfterSec}, errorReason`.

Forbidden fields: raw `text`, full assembled `prompt`, model `rationale` string. The rationale is sent to the client (it's part of the success response) but not to logs — the prompt rule says "no PII echo" but the model is the rule's enforcer, and a hallucinated rationale could quote the input. Treat as PII-adjacent.

### Files (server)

```
functions/
├── package.json            # type: module; firebase-admin@13, firebase-functions@7,
│                           # @google/genai@1, zod@3 (versions current as of v1.0.1)
├── tsconfig.json           # ES2022, strict, noUncheckedIndexedAccess
├── .eslintrc.cjs           # forbids functions.config, console.*
├── src/
│   ├── index.ts            # exports analyzeMoodText
│   ├── analyzeMoodText.ts  # onCall handler; runWith({secrets:[GEMINI_API_KEY]})
│   ├── geminiClient.ts     # SYSTEM_PROMPT + analyze(text, locale, signal)
│   ├── rateLimit.ts        # consumeToken(uid) via runTransaction
│   ├── types.ts            # wire types + Zod schemas
│   └── __tests__/analyzeMoodText.test.ts
```

### Files (Dart client)

```
apps/mobile/lib/features/mood/
├── domain/
│   ├── entities/ai_suggestion.dart        # @freezed; asserts confidence ∈ [0,1]
│   ├── ai_analysis_failure.dart           # sealed extends Failure (NOT MoodFailure)
│   ├── repositories/ai_analysis_repository.dart
│   └── usecases/analyze_mood_text.dart
└── data/
    ├── datasources/ai_analysis_functions_datasource.dart
    ├── dtos/ai_suggestion_dto.dart        # @freezed + json_serializable
    └── repositories/ai_analysis_repository_impl.dart
```

`AiAnalysisFailure` extends `Failure` (the abstract base in `packages/core/lib/src/failure.dart`) directly — *not* `MoodFailure` — because AI failures are conceptually distinct from mood-entity failures and may be reused by Sprint 4's pattern-analysis function.

## Alternatives Considered

- **Throw `HttpsError` for every error** (idiomatic Firebase pattern). Rejected: forces try/catch around every `.call()` on the Dart side and loses the `retryAfterSec` structured field. Result-typed responses produce cleaner state-machine UI.
- **Server-generated `requestId`**. Rejected: breaks idempotency-on-retry semantics. A client retrying a flaky call should pass the same `requestId` so the rate limiter can see it as one logical request (future enhancement; S3 just uses it for log correlation).
- **Memorystore / Redis for rate limits**. Rejected: adds infra. Firestore at 10 req/min/uid is ~$0.20/hr at 1000 active users — well within budget.
- **No `responseSchema` enum constraint** (parse Gemini's free-text response). Rejected: structured-output mode collapses the `parse_error` class to a rare exception rather than the norm. Belt-and-braces Zod re-check defends against schema drift.
- **Direct Gemini call from Flutter via the public REST endpoint with per-user OAuth**. Rejected: GeminiAPI key is a server credential; Cloud Functions proxy is the locked architecture per CLAUDE.md.

## Consequences

- Positive: AI failures degrade gracefully (manual mood pick always works); rate limit + auth bound abuse without App Check; PII never crosses log boundary; the wire format is stable enough that Sprint 4's compassionate-banner UX swap-in needs no protocol change.
- Negative: Cost of a Cloud Function call per user-keystroke-burst (debounced 600ms) is non-zero; if user-base grows the daily quota guard (open question §7 in the plan) becomes mandatory.
- Follow-up: ADR-0006 (Sprint 4) — App Check enforcement and `analyzePatterns` function for pattern detection. The wire format here is forward-compatible with `v: 2` if the prompt or response shape evolves.

## Compliance Check

- [ ] CLAUDE.md "Gemini via Cloud Functions proxy, never direct from app" — satisfied.
- [ ] CLAUDE.md "Never log PII (mood text, email, uid-with-text)" — satisfied (`text`, `prompt`, `rationale` excluded from logs; PII canary test #13).
- [ ] CLAUDE.md "Field-level security via `diff().affectedKeys()`" — N/A here; addressed in §D handoff brief for `firestore.rules`.
- [ ] CLAUDE.md feature-flag rollback (`ai_pattern_analysis_enabled`) — N/A here (pattern analysis is S4); but the `featureFlagsProvider` from D1.6 is the seam.
- [ ] Domain layer purity (`apps/mobile/lib/features/mood/domain/`) — `AiSuggestion` and `AiAnalysisFailure` import only `package:core/core.dart`; no Flutter or Firebase imports.

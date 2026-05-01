# Handoff Brief — Gemini Mood Detection (WBS 3.4)

**Sprint:** 3 (Day 3 morning → Day 4 morning)
**Owner:** flutter-engineer
**Rolling gate:** security-reviewer audits the Cloud Function as code lands (CLAUDE.md "do-not-do list" — `functions/src/*` requires security-reviewer sign-off; Gemini key exposure risk)
**WBS ID:** 3.4 (Gemini AI mood detection via Cloud Function proxy + confidence + override UX — highest-risk task in the sprint)

## Spec reference

The wire contract, validation order, prompt, logging schema, and error taxonomy are defined in **ADR-0003** (`docs/adr/0003-gemini-cloud-function-contract.md`). This brief is the implementation playbook — do not duplicate the ADR contents here, follow them.

## Acceptance criteria (Lin US-Lin-2)

> User types "ugh today was so long" → debounce 600ms → AI suggestion pill appears with mood + confidence + rationale → user taps **Use this** (single tap; mood + intensity chosen) **or** taps **Choose another** (pill dismisses, mood grid focused, override analytics event fires).

## Sequencing

### Day 3 morning — Server (TypeScript)

1. **`functions/package.json`** — Node 20 ESM (`"type": "module"`). Scripts: `build` (tsc), `serve` (firebase emulators), `deploy:staging` (firebase deploy --only functions --project=staging), `test` (jest --runInBand), `lint` (eslint). Deps: `firebase-admin@^12`, `firebase-functions@^5`, `@google/generative-ai@^0.21`, `zod@^3`. Dev: `typescript@^5.5`, `@types/node@^20`, `jest@^29`, `ts-jest`, `firebase-functions-test@^3`, `eslint`, `@typescript-eslint/parser`, `@typescript-eslint/eslint-plugin`. Engines: `"node": "20"`.

2. **`functions/tsconfig.json`** — `target: ES2022, module: ES2022, moduleResolution: bundler, strict: true, noUncheckedIndexedAccess: true, outDir: lib, rootDir: src, esModuleInterop: true`. Excludes `__tests__`.

3. **`functions/.eslintrc.cjs`** — extends `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `plugin:@typescript-eslint/recommended-requiring-type-checking`. Custom rules: `no-console: error`, `@typescript-eslint/no-floating-promises: error`, `no-restricted-imports: ['error', { paths: [{ name: 'firebase-functions', importNames: ['config'], message: 'Use defineSecret from firebase-functions/params' }] }]`.

4. **`functions/src/types.ts`** — wire types per ADR-0003 §"Wire format" + Zod schemas:
   ```ts
   export const AnalyzeMoodTextRequestSchema = z.object({
     text: z.string().min(1).max(500),
     requestId: z.string().uuid(),
     locale: z.string().min(2).max(8).optional(),
     v: z.literal(1),
   });
   export const GeminiResponseSchema = z.object({
     mood: z.enum(['happy','calm','okay','sad','angry','anxious']),
     confidence: z.number().min(0).max(2),       // accept up to 2 then clamp
     alternative: z.object({ mood: z.enum([...]), confidence: z.number().min(0).max(2) }).nullable(),
     rationale: z.string().max(120),
     flag: z.enum(['self_harm_safety']).nullable(),
   });
   ```

5. **`functions/src/rateLimit.ts`** — `consumeToken(uid: string): Promise<{allowed: boolean; remaining: number; retryAfterSec: number}>`. Uses `getFirestore()` admin SDK; encapsulates the transaction from ADR-0003 §"Rate limit". TTL on `rateLimits/{uid}.expireAt` policy must be configured in the Firebase console (operational task — capture as a separate operational checklist item, not in this brief).

6. **`functions/src/geminiClient.ts`** — `SYSTEM_PROMPT` constant (canonical text from ADR-0003 §"Gemini system prompt"), `analyze(text, locale, signal)` function. Imports `GoogleGenerativeAI`. Reads `GEMINI_API_KEY.value()` lazily inside the function. Generation config: `temperature: 0.2, topP: 0.9, maxOutputTokens: 200, responseMimeType: 'application/json', responseSchema: { ... enum-constrained ... }`. Wraps the SDK call with the abort signal. Emits the latency measurement.

7. **`functions/src/analyzeMoodText.ts`** — `onCall` handler. `runWith({ secrets: [GEMINI_API_KEY], timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: false, region: 'asia-southeast1' })`. Wires the validation pipeline per ADR-0003 §"Validation order".

8. **`functions/src/index.ts`** — `export { analyzeMoodText } from './analyzeMoodText.js';`. Nothing else in S3.

9. **`functions/src/__tests__/analyzeMoodText.test.ts`** — 14 cases per ADR-0003 §"Test plan". Mock `@google/generative-ai` at the top of file. Use `firebase-functions-test`'s `wrap(analyzeMoodText)`. The PII canary case (#13) is non-negotiable: input contains a sentinel string `"PII-CANARY-12345"`; assert no `logger.*` call's serialized payload contains the canary.

### Day 3 afternoon — Dart domain + data

10. **`apps/mobile/lib/features/mood/domain/entities/ai_suggestion.dart`** — `@freezed`. Asserts `confidence ∈ [0,1]` in factory (private `_validate` constructor pattern). Includes `AiSafetyFlag` enum (`selfHarm` only for S3).

11. **`apps/mobile/lib/features/mood/domain/ai_analysis_failure.dart`** — sealed `AiAnalysisFailure extends Failure` with variants:
    - `AiAnalysisFailure.unauthenticated()`
    - `AiAnalysisFailure.invalidInput(String reason)`
    - `AiAnalysisFailure.rateLimited(Duration retryAfter)`
    - `AiAnalysisFailure.geminiUnavailable()`
    - `AiAnalysisFailure.parseError(String reason)`
    - `AiAnalysisFailure.network()`
    - `AiAnalysisFailure.unknown(Object? cause)`
    
    Mirrors `mood_failure.dart` pattern. Imports only `package:core/core.dart`.

12. **`apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart`** — abstract:
    ```dart
    abstract class AIAnalysisRepository {
      Future<Result<AiSuggestion, AiAnalysisFailure>> analyzeMoodText({
        required String text,
        String? locale,
      });
    }
    ```
    No `userId` parameter — Cloud Function reads `request.auth.uid` from the Auth token automatically; client-passed `userId` would be both redundant and a trust-boundary violation.

13. **`apps/mobile/lib/features/mood/domain/usecases/analyze_mood_text.dart`** — `AnalyzeMoodTextUseCase`. Required by CLAUDE.md "use cases" rule (controllers must not depend on repositories directly).

14. **`apps/mobile/lib/features/mood/data/dtos/ai_suggestion_dto.dart`** — `@freezed` + `json_serializable`. Mirrors `AnalyzeMoodTextSuccess`. `toEntity()` method:
    - Parses `mood` via `MoodType.values.byName(dto.mood)`; if unknown → `Err(AiAnalysisFailure.parseError('unknown mood: $mood'))`. Defensive even though server's `responseSchema` should prevent it.
    - Clamps `confidence` to `[0, 1]`.
    - Returns `Result<AiSuggestion, AiAnalysisFailure>`.

15. **`apps/mobile/lib/features/mood/data/datasources/ai_analysis_functions_datasource.dart`** — wraps `FirebaseFunctions.instance.httpsCallable('analyzeMoodText')`. Single method `Future<Map<String, dynamic>> call({required String text, String? locale})`. Generates `requestId` via `Uuid().v4()`. Catches `FirebaseFunctionsException`:
    - `code === 'unauthenticated'` → throws typed `_UnauthenticatedException` (private to this file).
    - `code === 'unavailable' || 'deadline-exceeded'` → throws typed `_NetworkException`.
    - Other codes → bubbles the exception (repository wraps as `unknown`).

16. **`apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart`** — implements the abstract. Calls the datasource, switches on `payload['ok']`:
    - `true` → `AiSuggestionDto.fromJson(payload).toEntity()` (already a `Result`, return).
    - `false` → switch on `payload['code']`, map to `AiAnalysisFailure.*`. `rate_limited` reads `retryAfterSec` and constructs `Duration(seconds: ...)`.
    
    Catches `_UnauthenticatedException` → `AiAnalysisFailure.unauthenticated()`. Catches `_NetworkException` → `AiAnalysisFailure.network()`. Everything else → `AiAnalysisFailure.unknown(e)`. Logger usage matches `mood_repository_impl.dart:37` — never log input text; never log `failure.message` (could echo content); only log `failure.runtimeType.toString()`.

17. **`apps/mobile/lib/features/mood/data/providers.dart`** — append:
    - `aiAnalysisFunctionsDatasourceProvider` (singleton)
    - `aiAnalysisRepositoryProvider` (depends on datasource)
    - `analyzeMoodTextUseCaseProvider` (depends on repository)
    
    Same pattern as the existing `mood_firestore_datasource_provider` / `mood_repository_provider`.

### Day 4 morning — UX

18. **`apps/mobile/lib/features/mood/presentation/controllers/ai_suggestion_controller.dart`** — `@riverpod class AiSuggestionController extends _$AiSuggestionController`. `AsyncNotifier<AiSuggestion?>`. Debounces text changes with 600ms via a `Timer` reset on each input. On debounce fire, calls `analyzeMoodTextUseCaseProvider`. Reset to `AsyncData(null)` when the user manually picks a mood (the pill should not contradict an explicit choice).

19. **`apps/mobile/lib/features/mood/presentation/widgets/ai_suggestion_pill.dart`** — `ConsumerWidget`. Reads `aiSuggestionControllerProvider`. Three states:
    - **`AsyncLoading`** → shimmer placeholder + `Semantics(label: 'Analyzing mood', liveRegion: true)`. Non-blocking — the user can keep typing.
    - **`AsyncData(suggestion)` where `suggestion != null`** → tonal pill: leading mood emoji from `MoodType.icon` (TBD: ensure this exists in `mood_type.dart` — if not, add a feature-local helper), text "AI suggests {Suggested} — {confidence%}", trailing "Use this" `TextButton` and "Choose another" `TextButton`. **HIDDEN entirely** when `suggestion.safetyFlag == AiSafetyFlag.selfHarm` (S3 behavior; S4 swaps in compassionate banner).
    - **`AsyncError`** → tonal pill: "Couldn't analyze — pick manually." No retry button (next text change retriggers debounce).

20. **Modify `LogMoodController`** — add `applyAiSuggestion(MoodType mood)` method that updates `state.mood`. Do not auto-fill `intensity` from the suggestion (intensity is a deliberate user choice; the AI only suggests mood).

21. **Wire pill into `log_mood_screen.dart`** — render above the `MoodTypeGrid`, below the `MoodTextField`. Use `MoodBloomSpacing.md` for separation.

22. **Emit override analytics event** — when user taps "Choose another" then subsequently picks a mood manually, emit `AnalyticsEvent.aiSuggestionOverridden(suggested, final)` once. This is the Lin US-Lin-2 metric. The analytics package exists at `packages/analytics/` (currently a stub); the event class can be a simple data class for now — the full analytics pipeline lands in S4.

## Test plan (Dart side)

| File | Cases |
|---|---|
| `apps/mobile/test/features/mood/domain/entities/ai_suggestion_test.dart` | confidence < 0 / > 1 → assertion error; valid construction round-trips |
| `apps/mobile/test/features/mood/data/repositories/ai_analysis_repository_impl_test.dart` | wire ok=true → entity; wire ok=false code=rate_limited → `AiAnalysisFailure.rateLimited(Duration)`; wire mood='melancholy' → `parseError`; `_UnauthenticatedException` → `AiAnalysisFailure.unauthenticated`; logger asserted to never receive the input text |
| `apps/mobile/test/features/mood/presentation/widgets/ai_suggestion_pill_test.dart` | accept "Use this" → `LogMoodController.state.mood` updated; "Choose another" dismisses; loading shimmer; error fallback; **`safetyFlag == selfHarm` → pill not in widget tree** |
| `apps/mobile/test/features/mood/presentation/controllers/ai_suggestion_controller_test.dart` | rapid typing → only one Gemini call; mood manually picked → `AsyncData(null)` |
| `apps/mobile/test/_fakes/fake_ai_analysis_repository.dart` | (helper) hand-rolled fake with `nextResult` setter, mirrors existing `fake_mood_repository.dart` pattern |

## Security-reviewer rolling audit checklist

Run as code lands; do not wait for end of Day 3.

- [ ] No `functions.config()` anywhere (eslint rule blocks it; double-check via grep before merge).
- [ ] No `process.env.GEMINI_API_KEY` direct read (forces `defineSecret` ceremony).
- [ ] Input length cap enforced server-side (1..500); not just client-side.
- [ ] Rate limit transaction commits **before** the Gemini call (otherwise outage burst burns Gemini quota).
- [ ] Structured log line excludes `text`, full `prompt`, and `rationale` fields.
- [ ] PII canary test (#13 in ADR-0003) passes.
- [ ] App Check disable is region-scoped (S3 emulator only); not present on production deploy config.
- [ ] Cloud Function IAM: only the function's runtime service account can read the secret (Firebase auto-handles; verify no manual IAM grant added).
- [ ] No new dependencies on the deny list (`.claude/hooks/settings.json`).

## What NOT to do

- Do **not** modify `firebase/firestore.rules` in this brief — `rateLimits/{uid}` admin-only rule is in the Security Rules brief (`security-rules.md`).
- Do **not** implement `analyzePatterns` — that's S4 (US-Lin-3 pattern analysis).
- Do **not** turn on App Check — S4.
- Do **not** log Gemini's `rationale` field (the prompt rule says "no PII echo" but the model is the rule's enforcer; defense in depth = drop from logs).
- Do **not** auto-fill `intensity` from the suggestion — intensity is a deliberate user choice.
- Do **not** call Gemini directly from Dart — the Cloud Function proxy is the locked architecture.

## Files

Create:
- `functions/{package.json, tsconfig.json, .eslintrc.cjs}`
- `functions/src/{index.ts, analyzeMoodText.ts, geminiClient.ts, rateLimit.ts, types.ts}`
- `functions/src/__tests__/analyzeMoodText.test.ts`
- `apps/mobile/lib/features/mood/domain/{entities/ai_suggestion.dart, ai_analysis_failure.dart, repositories/ai_analysis_repository.dart, usecases/analyze_mood_text.dart}`
- `apps/mobile/lib/features/mood/data/{dtos/ai_suggestion_dto.dart, datasources/ai_analysis_functions_datasource.dart, repositories/ai_analysis_repository_impl.dart}`
- `apps/mobile/lib/features/mood/presentation/{controllers/ai_suggestion_controller.dart, widgets/ai_suggestion_pill.dart}`
- All test files listed above

Modify:
- `apps/mobile/lib/features/mood/data/providers.dart`
- `apps/mobile/lib/features/mood/presentation/log_mood_screen.dart`
- `apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.dart` (add `applyAiSuggestion`)
- `apps/mobile/pubspec.yaml` (add `cloud_functions`, `uuid`)
- `firebase.json` (add `functions` block)

## References

- ADR-0003 (`docs/adr/0003-gemini-cloud-function-contract.md`) — wire contract, prompt, validation, logging.
- CLAUDE.md "Gemini via Cloud Functions proxy" + "PR rules" + "Quick commands" (`npm run deploy:staging`).
- `apps/mobile/lib/features/mood/data/mood_repository_impl.dart:37` — canonical example of PII-safe logger usage to mirror.
- `apps/mobile/lib/features/mood/data/providers.dart` — provider pattern to extend.
- `apps/mobile/test/features/mood/domain/fakes/fake_mood_repository.dart` — fake pattern to mirror for `FakeAiAnalysisRepository`.

# HB-008 — Quote Library + Quote Safety Filter

**Author:** architect
**For:** flutter-engineer (Dart layer) + flutter-engineer (TypeScript CF layer) — same engineer can do both, but the security-reviewer audits the CF independently.
**Sprint:** 5 (May 13–19, 2026)
**WBS:** 5.5
**Related:** ADR-0003 (CF contract); ADR-0012 (Tier 3 determinism — required reading); HB-007 (dispatcher — composes this); `.claude/specs/sprint-4-5-spec.md` §3 (Quote Library Architecture), §7 TC-40, TC-41

## Goal

Provide the dispatcher with a quote at every dispatch. Tier 3 quotes come from a pre-approved curated pool with byte-for-byte determinism. Tier 1/2 quotes follow a hybrid path: Gemini suggests via a Cloud Function, the suggestion runs through a fail-closed `QuoteSafetyFilter`, filter reject or network failure falls back to a curated phrase. The filter and the curated pools are the safety net.

## Inputs

- `Tier` from the dispatcher (HB-007).
- `DisclaimerCopy` constants (already canonical).
- `geminiClient.ts` + `rateLimit.ts` (already present in `functions/src/`).

## Files to create

```
apps/mobile/lib/features/intervention/
├── domain/
│   ├── entities/
│   │   ├── quote.dart                    (Freezed: text, source enum
│   │   │                                  {curated, ai}, tier)
│   │   └── quote_failure.dart            (sealed Failure)
│   ├── repositories/
│   │   ├── quote_library.dart            (abstract: pickTier1,
│   │   │                                  pickTier2, pickTier3 with
│   │   │                                  date-seeded rotation)
│   │   └── ai_quote_repository.dart      (abstract:
│   │                                       requestSuggestion(
│   │                                          AiAllowedTier,
│   │                                          QuoteContext))
│   └── services/
│       └── quote_safety_filter.dart      (pure-Dart: gate(String)
│                                          returns Result<Quote,
│                                          FilterReject>)
└── data/
    ├── quote_library_impl.dart           (concrete: curated pools as
    │                                       static const Lists)
    └── ai_quote_repository_impl.dart     (calls suggestQuote CF)

functions/src/
├── suggestQuote.ts                       (NEW callable CF)
└── __tests__/
    └── suggestQuote.test.ts              (PII canary; rate-limit)
```

## QuoteSafetyFilter design

```
gate(String text) → Result<Quote, FilterReject>:

  1. Length check: text.length <= 140 → continue, else reject(length).
  2. Forbidden-word blacklist (case-insensitive whole-word match):
       depression, anxiety disorder, bipolar, diagnose, diagnosis,
       medication, prescribe, therapy, therapist, must, should, now,
       have to, need to, fix yourself, get better, overcome
       → match → reject(forbidden).
     (The blacklist is authored in this file as a `const Set<String>`;
      additions require team review.)
  3. Whitelist tag check: split text on whitespace; >= 80% of tokens
     must appear in the tier's `approvedWordSet`. If <80% → reject(
     offScript). Word sets live next to the curated pools, so the same
     vocabulary that informs the curated phrases informs what Gemini
     is allowed to echo.
  4. Pass → return Ok(Quote(text, source: ai, tier: <tier>)).

Test (TC-41): feed 50 synthetic strings, each containing at least one
forbidden token or violating the length cap or the whitelist ratio.
Assert 100% rejection. Include 5 "almost-OK" strings (single forbidden
word in an otherwise valid phrase) to ensure the filter does not
silently let them through.
```

## Curated pool authoring

```
QuoteLibrary.tier1Pool — 12 entries
  examples:
  "It looks like your garden has had some rainy days. Would you like a
   2-minute breathing exercise?"
  "Rainy days happen. A short breath might help — only if you'd like."
  ...

QuoteLibrary.tier2Pool — 12 entries
  examples:
  "Would you like to write about what's been on your mind?"
  "Sometimes putting feelings into words helps. Want to try?"
  ...

QuoteLibrary.tier3Pool — 8 to 12 entries
  examples:
  "We care about you. If it helps to talk, the Thai Mental Health
   Hotline is free at 1323, 24 hours."
  "These feelings can be very heavy. You don't have to face them
   alone. Hotline 1323 is available any time."
  "Reaching out for support is a sign of strength. Hotline 1323
   connects to trained listeners, free, 24 hours."
  ... (team-expand to 8–12 before merge)
```

**Authoring rules:**

- Every pool entry passes its own tier's `QuoteSafetyFilter` (sanity check; unit test asserts this for all pool entries).
- Tier 3 entries always end with "Hotline 1323" or include it in the body. The dispatcher appends `DisclaimerCopy.notificationFooter`; the curated entry does not duplicate it.
- Team reads aloud before merge. Tier 3 read aloud twice. PR description includes the read-aloud sign-off line; missing sign-off → revert.

## Rotation

`pickTier3(seed: DateTime)` deterministically picks an index by `seed.toUtc().day % tier3Pool.length`. Same date → same phrase across devices; next day → next phrase. Tier 1/2 use a different seed (`seed.weekId` so phrases vary across weeks but not within a week — the dispatcher hits at most once per 48h, so this is cosmetic).

## suggestQuote.ts Cloud Function spec

```ts
// region: 'asia-southeast1'
// runtime: node 20
// enforceAppCheck: true
// memory: '256MiB'
// timeout: 30s

input: {
  tier: 1 | 2,               // NEVER 3 — runtime guard rejects 3 with
                             // 'invalid-argument'
  context: {
    weekId: string,          // e.g. "2026-W19"
    dailyAvgS: number,       // -1.0..+1.0
    dominantEmotion: string  // one of the 6 mood enums
  }
}

forbidden in payload (asserted by PII canary test):
  - userId
  - moodText (raw user text)
  - email
  - any FCM token

system prompt (locked, version-controlled in this file):
  "You are a gentle companion for a mood-tracking app. Suggest a
   single supportive sentence (max 140 characters) inviting the user
   to a {tier=1: breathing exercise | tier=2: journaling prompt}.
   Forbidden words: depression, anxiety disorder, bipolar, diagnose,
   medication, therapy, must, should. Use compassionate language
   only. Reply with the sentence only — no quotes, no preamble."

model: gemini-2.5-flash
temperature: 0.4
maxOutputTokens: 80

rate-limit: 10 calls / uid / day via packages/core/rateLimit.ts
  (already exists; reuse).

output: { suggestedText: string }
errors:
  - invalid-argument (tier=3, malformed input)
  - resource-exhausted (rate-limit hit)
  - internal (Gemini failure — client falls back to curated)
```

## Acceptance

- TC-40 (Tier 3 determinism): covered by HB-007 + ADR-0012; this brief's contribution is to **not expose** an `AIQuoteRepository` method that accepts `Tier.three`. The `AiAllowedTier` enum is the type-level fence.
- TC-41 (Safety Filter): 50 forbidden-term inputs → 100% reject.
- Pool sanity (TC-38 contribution): every curated pool entry passes its tier's own filter. Unit test in `quote_library_test.dart`.
- Rate-limit on `suggestQuote.ts`: per-uid 10/day. Test in `__tests__/suggestQuote.test.ts`.
- PII canary on `suggestQuote.ts`: no `userId`, no `moodText`, no `email`, no FCM token in the outbound Gemini payload. Test asserts by intercepting the Gemini SDK call.

## Open questions for the engineer

- **OQ-A:** Should `QuoteContext.dominantEmotion` flow to Gemini, or only `dailyAvgS`? Default: **emotion flows**, since the 6 emotion enums are not PII. Confirm with security-reviewer at start of Day 2.
- **OQ-B:** Should curated pools be authored in code (current plan) or in Remote Config so non-engineers can edit? Default: **code**, so the pool ships with the binary and cannot be tampered with via a Remote Config push. Remote Config is for kill-switches, not for safety-critical content.

## Non-goals

- Do not call Gemini for Tier 3, ever, anywhere in this feature.
- Do not log raw Gemini output to Crashlytics or the structured logger — only log the post-filter `source` (curated / ai) and the `quoteId`. Raw quote text is fine for in-app display but never for observability.
- Do not bypass the filter "in dev". If Gemini is down in development, the curated fallback is the dev experience too.

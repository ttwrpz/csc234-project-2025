# ADR-0012 — Tier 3 Determinism: Curated-Only Path with Gemini-Mock Verification

**Status:** Accepted (Sprint 5)
**Date:** 2026-05-13
**Deciders:** orchestrator + architect + security-reviewer
**Related:** ADR-0003 (Cloud Function contract); ADR-0007 (statistical-primary pattern analysis); ADR-0008 (cooldown persistence); ADR-0011 (client-side pattern engine); `.claude/specs/sprint-4-5-spec.md` §3 (Quote Library Architecture), §7 TC-40/TC-41; HB-007 (Tiered Intervention dispatcher); HB-008 (Quote Library + Safety Filter)

## Context

Tier 3 fires when the Pattern Engine detects an acute pattern: three consecutive S ≤ -0.6, or a single-day z-score crash (z_day < -2.5), or a CUSUM change-point breach. At that moment the user is at their most vulnerable. The Sprint 4–5 spec (§3.1) commits the team to a non-negotiable rule: **Tier 3 messages NEVER call Gemini, EVER.**

Gemini 2.5-flash is a probabilistic generator. Even with a locked prompt and `temperature: 0.4`, it can produce off-script output — clinical labels ("depression"), urgency words ("must"), or phrasing that an LLM finds neutral but a vulnerable user finds harmful. The Quote Safety Filter catches obvious cases, but the residual risk at Tier 3 — where the bottom of the distribution is "real-world harm" — is unacceptable.

The argument for personalization at Tier 3 is weak: the user is in acute distress, not browsing for variety, and the curated pool ("We care about you. If it helps to talk, Hotline 1323 is available 24 hours.") is purpose-engineered with self-compassion (Neff 2003) and DBT validation (Linehan 1993) principles, then team-reviewed aloud before merge.

Sprint 4 left the cooldown anchors in place (ADR-0008) and the Pattern Engine surfacing `Tier` triggers (ADR-0011), but the dispatcher itself was not wired. Sprint 5 wires it. This ADR locks in the determinism guarantee at the type and test level so that no future edit — code, prompt, or refactor — can route a Tier 3 dispatch through Gemini without breaking a test.

## Decision

1. **Type-level branch.** `TieredInterventionDispatcher.dispatch(Tier tier, …)` switches on `tier`. The `Tier.three` arm calls `QuoteLibrary.pickTier3(seed: …)` directly and returns. It does not touch `AIQuoteRepository`, `QuoteSafetyFilter`, or any Gemini-adjacent type. The other two arms (`Tier.one`, `Tier.two`) go through `AIQuoteRepository → QuoteSafetyFilter → fallback to curated on filter-reject`.

2. **Compiler-level fence.** `AIQuoteRepository.requestSuggestion` accepts a constrained input type `enum AiAllowedTier { one, two }`. `Tier.three` cannot be passed without a deliberate enum conversion, which the dispatcher does not perform. A reviewer reading the dispatcher should see the Tier 3 arm and understand at a glance that no Gemini call is reachable.

3. **Test-level fence (TC-40).** The dispatcher test creates a `class _MockAIQuoteRepository extends Mock implements AIQuoteRepository` via `mocktail`. For each seeded Tier 3 trigger pattern (3-consecutive S ≤ -0.6, z_day < -2.5, CUSUM breach):
   - The dispatcher is invoked end-to-end.
   - `verifyNever(() => mockAIRepo.requestSuggestion(any()))` is asserted. Failing this assertion fails the test and the build.
   - The returned `InterventionDispatch.body` is asserted to appear verbatim (`contains` substring after stripping the disclaimer footer) in the static `QuoteLibrary.tier3Pool` constant list.
   - The `Tier 3 → AIQuoteRepository` code path is also unreachable via the type system, so the only way the verify fires is if a future edit deliberately breaks both fences. The test exists so that such a break surfaces in CI on the same PR.

4. **Safety Filter does not gate Tier 3.** Tier 3 messages come from a pre-approved pool, byte-for-byte. The filter would be redundant; it also masks the intent (someone reading the code should not see Tier 3 traversing the filter and wonder whether the filter is the guarantee). The filter remains exclusively on the Tier 1/2 hybrid path.

5. **Curated pool reviewed aloud.** Before any merge that adds or edits a Tier 3 phrase, the entire team reads each phrase aloud at least twice. A merge that touches `QuoteLibrary.tier3Pool` and lacks the sign-off line in the PR description is reverted. The pool size target is 8–12 entries to give variety without diluting review discipline.

## Consequences

**Good**

- Real-world harm at the most vulnerable moment is structurally impossible — not "very unlikely," not "tested," but unreachable in the call graph.
- A future engineer adding a new tier-3-adjacent feature cannot accidentally route through Gemini; the type and test fences trip on the same change.
- TC-40 doubles as documentation: reading the test tells the next engineer what the invariant is and why.
- The Tier 1/2 hybrid path retains personalization where it is safe and where the Safety Filter is the appropriate defence.

**Bad**

- No personalization at Tier 3. Acceptable: the curated pool is small but purpose-built; rotation by `seed: dateOnly(today)` ensures the user does not see the same phrase twice within a short window.
- The Safety Filter cannot be the sole defence for Tier 1/2; the team is committed to a non-trivial curated fallback pool for those tiers as well, which is more authoring work than a Gemini-only system would have required.

## Alternatives Considered

- **Tier 3 with Gemini at `temperature: 0` and a locked prompt.** Rejected. Temperature zero is not actually deterministic across Gemini versions; the model could be retrained and produce a different "deterministic" output on the same prompt. A 12-month product cannot depend on Gemini's internal stability.
- **Tier 3 with Gemini gated only by the Safety Filter.** Rejected. Filter false-negatives exist in principle (the filter cannot enumerate every harmful phrase). The residual risk at Tier 3 is not proportional to the personalization benefit.
- **Tier 3 with a single curated phrase, no rotation.** Rejected as a UX dead-zone — a user who repeatedly experiences Tier 3 weeks would see the same string every time, undermining the felt-care signal. Rotation across 8–12 entries seeded by date preserves variety without compromising the determinism guarantee.

## Compliance Check

- Clean Architecture domain-zero-imports rule: satisfied. `TieredInterventionDispatcher`, `QuoteLibrary`, `QuoteSafetyFilter`, `AIQuoteRepository` (abstract) all live in `apps/mobile/lib/features/intervention/domain/`. None import Flutter or Firebase.
- Enterprise Term Assignment requirements touched: **R3** (architecture quality — the type-level fence is the textbook example of "make illegal states unrepresentable"); **R5** (security and safety — the most consequential safety invariant in the codebase is enforced at three layers: code, types, tests).
- Quality gates affected: **Correctness** (TC-40 in CI); **Security** (no Gemini reach from Tier 3, asserted continuously). Performance unaffected — Tier 3 is the fastest path (no network round-trip).
- CLAUDE.md feature-flag rollback: `ai_pattern_analysis_enabled` gates the Tier 1/2 Gemini path. If disabled, Tier 1/2 falls back to curated phrases (HB-008). Tier 3 is unaffected — it was never gated on this flag because it was never on the Gemini path.
- CLAUDE.md do-not-do list — `firestore.rules` writes on `/cooldowns/` and `/interventions/` are covered by HB-007; this ADR does not edit rules directly. `functions/src/suggestQuote.ts` is covered by HB-008 with security-reviewer sign-off.

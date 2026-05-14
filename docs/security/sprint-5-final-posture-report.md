# Sprint 5 - Final Security Posture Report (v1.5 release)

**Reviewer:** security-reviewer agent
**Date:** 2026-05-18
**Audit head:** 77ade6e7aa43fa72996748df44b6aee0b8db2aff
**Scope:** S5 mainline b7a95104..77ade6e7 (13 commits)
**Tag target:** v1.5 (May 19)
**Supersedes:** Sprint 5 Day 2 interim Security Posture Report

---

## Summary

Recommendation: GO, conditional on one MEDIUM-severity sweep (D-M01, pnpm audit HIGH advisories - all transitive, none reachable from attacker-controlled input) being filed as a v1.6 ticket. All interim Day-2 findings (R-H01, R-M01/02/03, R-L02/L03/L04, R-L01) have been verified PASS in commit c1ca5021. Day 3+ commits (449acdd9 integration tests, d7728d8b + f38408c1 a11y, 77ade6e7 docs) are test-only / docs-only and introduce no new code-path attack surface. The Tier 3 fence - ADR-0012 structural invariant that Gemini is unreachable from the crisis path - is now confirmed at 5 defence-in-depth layers (type, dispatcher branch, CF schema, dispatcher unit test, controller unit test, plus the new integration test). Findings: 0 Critical, 0 High (see D-M01 caveat), 1 Medium, 3 Low / Info.

---

## Re-audit of interim findings

### R-H01 (HIGH) - Storage media cascade - PASS

The Storage step is implemented at functions/src/wipeUserData.ts:159-177 (L161 getStorage().bucket(), L162 prefix set to users/{uid}/media/, L163 bucket.getFiles({prefix}), L165 bucket.deleteFiles({prefix, force: true})).

- Prefix matches firebase/storage.rules:4 (/users/{uid}/media/{path=**}).
- Error handling at L166-177 is best-effort: the catch logs and falls through; the rest of the cascade (profile reset + rate-limit cleanup at L189-217) still completes.
- PII canary holds (L172-176): the warn payload is {event, uid, errorName} only - no object names, no error message body. Verified by test at functions/src/__tests__/wipeUserData.test.ts:320-343 (Storage SDK failure does NOT abort the cascade) and L345-357 (PII canary - Storage object names never appear in any log payload) with the super-secret-mood-photo-2026-05-13.jpg canary string.
- The synthetic seed at test L301-302 (canary.jpg, sub/dir/other.png) plus the assertion at L306-309 (bucketMock.deleteFiles called exactly once with {prefix: users/test-uid/media/, force: true}) proves the cascade reaches the SDK with the expected arguments.

Citations: wipeUserData.ts:160-177, wipeUserData.test.ts:295-357, storage.rules:4.

### R-M01 (MEDIUM) - Rate-limit doc cleanup - PASS

Four collections are now swept at wipeUserData.ts:68-73:

- rateLimits
- rateLimits.patterns
- rateLimits.cheerUp
- rateLimits.suggestQuote

Cleanup loop at L208-217 iterates all four with try/catch per doc; not-found is treated as success per admin SDK semantics. Test coverage at wipeUserData.test.ts:363-406 includes the four-doc happy path (L364-383, asserts rateLimitDeletedCount: 4 and all four docs absent post-call) plus the partial-failure case (L385-405, one missing plus one throws - cascade still returns ok: true).

### R-M02 (MEDIUM) - Idempotency contract - PASS

{ok: true, alreadyDeleted: true} short-circuit at wipeUserData.ts:107-122. The signal is profile doc absent AND moods subcollection empty (L112-118); a single doc-existence check plus one limit(1) query. Returns before touching Storage (verified by wipeUserData.test.ts:429-452: bucketMock.deleteFiles).not.toHaveBeenCalled() at L441). The third test at L454-468 confirms the function does NOT short-circuit when only the profile is gone but moods survived - it proceeds with the cascade.

### R-M03 (MEDIUM) - Runtime options + App Check posture - PASS

Declared at wipeUserData.ts:237-254:

- region: asia-southeast1 (L243) - pinned, matches the rest of the suite.
- timeoutSeconds: 540 (L244) - matches ADR-0009 and is the Cloud Functions v2 maximum.
- memory: 512MiB (L245) - matches ADR-0009.
- enforceAppCheck left absent, documented at L246-252 with the project-precedent rationale (cross-references analyzeMoodText.ts:307-321). This matches the suggestQuote.ts:296 enforceAppCheck: false posture.

### R-L01 (LOW / INFO) - App Check posture - DEFERRED to v1.6

Documented as project-wide precedent at wipeUserData.ts:246-252, suggestQuote.ts:282-289. ADR-0009 amendments section (see R-L03 below) makes this explicit. Defer to v1.6 alongside web App Check init.

### R-L02 (LOW) - Header comment dual-use - PASS

wipeUserData.ts:1-36 documents both (a) production cascade via DeleteAccountFunctionsDatasource and (b) debug-reset path. Cascade order, idempotency contract, PII discipline, and callable contract all present.

### R-L03 (LOW) - ADR-0009 name + posture drift - PASS

docs/adr/0009-account-deletion-topology.md carries an Amendments section dated 2026-05-13 documenting (1) wipeUserData deployed name vs deleteAccount documented name, (2) enforceAppCheck v1.6 deferral with rationale, (3) confirmation that rate-limit-doc plus Storage-media steps are now both implemented.

### R-L04 (LOW) - Firestore TTL on rate-limit docs - DEFERRED to v1.6

Inline cleanup is the v1.5 posture (wipeUserData.ts:201-217); console-side TTL config is a v1.6 ops ticket. The header comment at L66 already notes the TTL design intent.

---

## New findings (Day 3+ commits)

### HIGH

None - Day 3 commits are test-only plus a11y wrappers plus docs.

### MEDIUM

**D-M01 - pnpm audit HIGH advisories (3 transitive).**

pnpm audit --audit-level=high from functions/ reports 5 advisories (1 LOW, 1 MODERATE, 3 HIGH). All three HIGH advisories are transitive:

- fast-xml-builder@1.1.5 via firebase-admin > @google-cloud/storage > fast-xml-parser > fast-xml-builder. HIGH (XML attribute injection, GHSA-5wm8-gmm8-39j9). Reachable via wipeUserData.ts:163-165 Storage SDK calls - but the XML response body is generated by Google Cloud Storage, an upstream-controlled surface. No user input flows into the XML being parsed. Practical exploitability against MoodBloom: near-zero.
- fast-uri@3.1.0 (two distinct advisories) via @google-cloud/functions-framework > cloudevents > ajv > fast-uri. HIGH (path traversal GHSA-q3j6-qgpj-74h6 plus host confusion GHSA-v39h-62p7-jpjc). The cloudevents parser is used by functions-framework for v1 background functions only; our deployed CFs are all v2 onCall (index.ts:18-23). Not reachable from the v2 callable code path in production.

Status: fix next sprint (v1.6). Recommendation: project owner to add pnpm update firebase-admin @google-cloud/functions-framework as a v1.6-opening chore to absorb upstream patches when they ship. Not a v1.5 blocker - no production input reaches either vulnerable parser via attacker-controllable bytes.

### LOW

**D-L01 - functions/package.json uses pnpm-lock.yaml only; npm audit fails ENOLOCK.** Documentation gap, not a security gap. Project uses pnpm exclusively (package.json:8 declares packageManager: pnpm@10.18.0). The interim audit checklist reference to npm audit --audit-level=high should be amended in the next agent prompt revision to pnpm audit --audit-level=high. Filed as info.

**D-L02 - cooldowns/{type} rule allows owner writes; the dispatcher path uses the admin SDK.** firestore.rules:300-320 permits the owner to update lastDispatchedAt / cooldownUntil directly. The dispatcher state machine writes via the admin SDK (intervention_repository_impl.dart calling the use case), but the client-side write path remains a possible self-DoS (the user could nudge their own cooldown forward). Risk is bounded - affects the user own intervention cadence only - and the field-level allowlist plus server-timestamp check (L305, L315) prevents tampering with dispatchedAt. Not a v1.5 issue, but worth flagging for v1.6: consider tightening to admin-SDK-only writes once the use case is fully proven.

### Informational

**D-I01 - Test-only files: 0 production code changes in f38408c1 and 449acdd9.** Verified via git show --stat:

- f38408c1 - all 12 modified paths are under test/ or docs/test-reports/. Zero production code touched. Matches the commit message claim.
- 449acdd9 - all 7 modified paths are under integration_test/. Zero production code touched.
- 77ade6e7 - 2 modified paths, both under docs/test-reports/. Docs only.

**D-I02 - d7728d8b a11y baseline has 3 inline production fixes** at disclaimer_ack_dialog.dart (adds scrollable: true), cheer_up_banner.dart (ExcludeSemantics on the cherry-blossom emoji), and settings_screen.dart _Avatar (ExcludeSemantics on decorative gradient). All three are pure additions - no behaviour changes, no logging touched, no PII surface. Spot-checked the diffs: +7, +9/-2, +39/-17 lines (formatting noise dominates the third).

---

## V1.5 release gate findings

### Secret scan

Result: CLEAN.

- git diff b7a95104..77ade6e7 filtered for AIza[A-Za-z0-9_-]{16,}, sk-[A-Za-z0-9_-]{16,}, AKIA[A-Z0-9]{16}, ghp_[A-Za-z0-9]{16,}, PEM-style BEGIN markers, and literal password= / secret= patterns across apps/mobile/lib/, functions/src/, firebase/. No matches.
- lib/firebase_options.dart is the only file flagged by a naive AIza* pattern scan; it carries the public Firebase web/Android API keys (acceptable per project precedent - these are public configuration, restricted by Firebase Auth security and the domain-allowlist at the Google API Console; see docs/security/api-key-restrictions.md).
- Gemini API key is referenced via Firebase Functions Secret Manager at functions/src/geminiClient.ts:GEMINI_API_KEY and consumed in suggestQuote.ts:126 - never literal in source.

### Dependency hygiene

**Mobile (flutter pub deps):** 1 new dependency in S5 vs the v1.0 baseline:

- url_launcher ^6.3.1 (resolved 6.3.2) - first-party (flutter.dev). Used at crisis_resources_screen.dart:56 for tel:1323 and https:// resource links. No CVEs in 6.3.x. Pinning at ^6.x.x is acceptable - this is not an auth/crypto/http-internals package and the team maintains it.

No HIGH or CRITICAL advisories detected against Dart deps via pub.dev/security-advisories cross-reference. All Firebase Flutter plugins are on firebase_core 4.7.0 family which is current.

**Functions (pnpm audit --audit-level=high):** 3 HIGH advisories - see D-M01 above. None reachable from attacker-controllable input in the deployed v2 callable path.

### PII logging audit

Sweep result: CLEAN. Walked every logger.info/warn/error/debug call introduced or modified in the S5 diff:

**Cloud Functions:**

- suggestQuote.ts:190, 219, 231, 259, 274 - payloads use the LogPayload type (L83-91) with allowlisted keys only: event, uid, outcome, tier, latencyMs, errorReason, and the rateLimit envelope. No suggested text, no dailyAvgS, no dominantEmotion, no weekId. PII canary test at suggestQuote.test.ts:316 enforces this.
- wipeUserData.ts:119, 172, 219 - payloads carry event + uid + counts only. PII canary test at wipeUserData.test.ts:474-516 plants PII-CANARY-MOOD-TEXT-XYZ and PII-CANARY-FILE-XYZ in seeds and asserts neither appears in any logger payload.

**Mobile:**

- intervention_controller.dart:146, 277 - strings only or failure.runtimeType.toString(). No body, no uid, no quote text.
- ai_quote_repository_impl.dart:107-115 - log keys allowlisted to tier, source, durationMs, succeeded. Explicit comment at L100-101: No PII, no suggested text, no userId.
- notifications_firestore_datasource.dart:52, 101 - migrated flag plus cheerUpEnabled bool only. Comment at L51 cites CLAUDE.md PII rules.
- intervention_repository_impl.dart:48, 61, 67, 78, 94, 100, crisis_resources_screen.dart:56, 73, fcm_token_repository_impl.dart:47, 52, 63, 66, 90, 93, 149, 152 - short strings, e.code (FirebaseException error codes only - these are enums, not messages), or runtimeType.toString(). No FCM tokens logged.

Forbidden-payload checklist:

- Raw mood text: 0 occurrences.
- User email: 0 occurrences (auth fakes are scoped to test code).
- Quote suggestion text post-Safety-Filter: 0 occurrences.
- FCM tokens: 0 occurrences (fcm_token_repository_impl.dart catches e.code only).
- Storage object names: 0 occurrences (re-confirmed against wipeUserData.ts:172-176).
- dailyAvgS floats: 0 occurrences in logs; appears only in the Gemini prompt body (suggestQuote.ts:108) and the production CF test asserts it never enters log payloads.

### Firestore rules drift

Re-read firebase/firestore.rules:1-368. All pre-S5 rules intact; S5 additions are net-new match blocks. Per-rule confirmation:

- **users/{uid}.insightsDisclaimerAcked one-way (false to true):** intact at firestore.rules:23-29 - the rule was added by 8965c2a3 and has not been weakened by any later commit.
- **users/{uid}/moods/{moodId} 24h same-day mutability window:** intact at L55-74. The same-UTC-day check on update (L56-58) and delete (L72-74) is unchanged; affectedKeys().hasOnly([...]) at L62-63 enforces the field allowlist.
- **users/{uid}/weeklyGardens/{weekId} write-once:** intact at L341-360 - allow update, delete: if false at L359.
- **users/{uid}/interventions/{id} one-way optedOut transition:** fresh in S5 at L265-291. Create at L268-279 forces optedOut == false on creation (L275); update at L284-288 restricts the diff to ['optedOut'] only AND requires the false to true transition (L287-288). dispatchedAt, tier, quoteId, cooldownUntil, schemaV are all immutable post-create. allow delete: if false at L290.
- **users/{uid}/cooldowns/{type} field-level allowlist:** at L300-320, affectedKeys().hasOnly(['lastDispatchedAt', 'cooldownUntil']) (L313-314), server-timestamp check on lastDispatchedAt (L315), cooldownUntil > request.time (L317).
- **users/{uid}/settings/notifications four-flag allow-list:** at L158-191. Create AND update both enforce keys().hasOnly([...]) / diff().affectedKeys().hasOnly([...]) (L170-172, L183-185) with the same six-key envelope (cheerUpEnabled, tier1Enabled, tier2Enabled, tier3Enabled, tokens, updatedAt). Type checks at L163-168 / L176-181. tokens is capped at 25 entries.

No client write can bypass the field allowlist on any S5 collection.

### Cloud Function security re-check

**suggestQuote.ts:**

- Region pinned at L292 (asia-southeast1).
- Rate-limit consume order: L177-199 schema validation FIRST, then L201-236 rate-limit consume, then L238-262 Gemini call. Malformed input cannot burn the budget - confirmed.
- Logger payloads (L184-191, L210-220, L222-236, L246-260, L266-274) carry event + uid + outcome + tier + latencyMs + errorReason + the rate-limit envelope only. No suggested text, no dailyAvgS, no dominantEmotion.
- Tier 3 rejected at the Zod boundary (L62: z.union([z.literal(1), z.literal(2)])); the HttpsError message at L196-198 names the invariant by reference to ADR-0012.

**wipeUserData.ts:**

- Region pinned at L243 (asia-southeast1).
- Idempotency short-circuit BEFORE cascade (L112-122) so a re-run on a cleaned account does no work and writes no logs except wipeUserData.alreadyDeleted.
- Profile-reset write (L189-199) uses set(merge: true) so legitimate future schema additions are not clobbered.
- Logger payloads (L119, L172-176, L219-225) carry event + uid + counts only.

### Tier 3 fence - 5-layer confirmation

All five defence-in-depth layers verified:

1. **Type fence:** apps/mobile/lib/features/intervention/domain/entities/ai_allowed_tier.dart:12-29 - enum AiAllowedTier {one, two} cannot represent Tier 3; fromTier throws StateError on Tier.three (L24-27). The throw path is documented as belt-and-suspenders - unreachable in practice because of layer 2.
2. **Dispatcher branch:** tiered_intervention_dispatcher.dart:70-74 - if (tier == Tier.three) { quote = _quoteLibrary.pickTier3(seed: now); } returns before any AI-adjacent type is referenced.
3. **CF schema:** suggestQuote.ts:62 - Zod schema rejects tier: 3 at the function boundary; error message at L196-198 makes the invariant visible.
4. **Dispatcher unit test:** tiered_intervention_dispatcher_test.dart:125-131 - expect(ai.calls, isEmpty, reason: ADR-0012 Tier 3 must never reach Gemini). Filter calls also isEmpty (L133).
5. **Controller unit test:** intervention_controller_test.dart:417-423 - expect(aiRepo.calls, isEmpty, reason: Tier 3 dispatches must never invoke AIQuoteRepository.requestSuggestion (ADR-0012 + TC-40)).
6. **NEW Integration test:** apps/mobile/integration_test/intervention_tier_3_test.dart:151-162 - the hard assertion verbatim:

```
expect(
  aiRepo.calls,
  isEmpty,
  reason:
      'ADR-0012 Decision point 1: Tier 3 must NEVER invoke '
      'AIQuoteRepository.requestSuggestion. Real-world harm at '
      "the user is most vulnerable moment is structurally "
      'impossible - not very unlikely, not tested, but '
      'unreachable in the call graph. A future refactor that '
      'routes Tier 3 through Gemini (intentionally or accidentally) '
      'fails THIS assertion on the same PR.',
);
```

The test exercises the real production controller + dispatcher pipeline (overrides only aiQuoteRepositoryProvider to the recording fake at L106 and the supporting fakes for repos/state/FCM at L107-112; everything else is real). The recording fake itself (intervention_fakes.dart:37-64) records every requestSuggestion call into calls of type List<({AiAllowedTier tier, QuoteContext ctx})>.

Five layers (six if the dispatcher unit test filter-also-empty assertion is counted separately). The integration test specifically exercises the same invariant at the running-app level so a future regression that swaps the dispatcher tier-3 arm for a hybrid path fails BOTH the unit and the integration suite on the same PR.

### Integration test bypass check

Re-read auth_smoke_test.dart, mood_log_smoke_test.dart, ai_override_test.dart, harvest_cycle_test.dart, intervention_tier_1_2_test.dart, intervention_tier_3_test.dart. None of them:

- Import firebase_admin or any server-side SDK from Dart.
- Bypass the auth guard - every test sets up an IntegrationAuthRepository (integration_test/fakes.dart:27-110) that emits AppUser values through the same currentUserStreamProvider the production router consumes.
- Reach into Firestore directly - Drift in-memory plus repo fakes only.

Test-only state is constrained to test scope; the production call graph is exercised against fakes, not bypassed.

---

## Skin-system parallel branch - out of scope

The flower-skin-system work on parallel branches a87a347d (feat/s5-d1-skin-system) + 11b66274 (feat/s5-d2-skin-widget-tests) is not yet merged into the S5 mainline at 77ade6e7. This audit does not cover those commits.

**Flag for tag preparation:** if the skin-system branches are squash-merged or rebased into the v1.5 tag head before tagging (per the Day-4 runbook integration step), the v1.5 tag will contain skin-system code that has NOT received a security-reviewer pass. The specific surfaces deferred to a v1.6 audit by f38408c1 a11y agent report (skin_modal_sheet, spend_confirmation_dialog, per_flower_detail_modal - all under tokens/presentation/widgets/) include user-facing inputs (spend amount, confirm flow) that should get a dedicated audit pass before they ship.

**Recommendation:** either (a) tag v1.5 from 77ade6e7 without the skin system and ship the skin system in a v1.5.1 point release after audit, or (b) request a brief security re-sweep covering only the delta from a87a347d + 11b66274 (estimated 30 minutes; primarily Firestore-rule re-check for unlockedSkins writes plus token spend atomicity) before tagging. Orchestrator to decide.

---

## Recommendation for v1.5 tag

**GO - conditional.** All Day-2 interim findings re-verified PASS. Day 3+ commits introduce no new production attack surface. The Tier 3 fence (the highest-stakes invariant in the project) is now confirmed across 5+ defence-in-depth layers including the new integration test. Firestore rules are tight, Cloud Functions are tight, PII discipline holds across the diff.

Conditions:

1. **File D-M01 as a v1.6-opening chore** to absorb upstream patches for fast-xml-builder (transitive via @google-cloud/storage) and fast-uri (transitive via @google-cloud/functions-framework). Neither is reachable from attacker-controllable input in the deployed v2 callable surface, but the advisories are HIGH and should not linger.
2. **Decide on the skin-system branch posture before tagging** - either exclude (tag from 77ade6e7) or audit the approximately-30-minute delta from a87a347d + 11b66274 first. The S5 mainline audit findings stand either way; only the skin code itself needs the additional pass.
3. **Confirm the Day-5 final-smoke runbook (docs/test-reports/sprint-5-cross-platform-runbook.md) passes its done-criteria checklist on Android emulator + Chrome web** before pushing the tag. The security posture is sound; cross-platform correctness is the remaining release-gate concern, owned by qa-engineer not by this audit.

If those three conditions are met, the v1.5 tag may be pushed.

---

## Sign-off

**Audit head:** 77ade6e7aa43fa72996748df44b6aee0b8db2aff
**Reviewer:** security-reviewer agent
**Date:** 2026-05-18
**Status:** GO (with three conditions listed above)
**Supersedes:** the Sprint 5 Day 2 interim Security Posture Report.

This report recommendation is BINDING for the v1.5 tag decision.

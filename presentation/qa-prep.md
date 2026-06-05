# MoodBloom — Q&A Preparation

**Release:** v1.6 · commit `0e55021a` · generated 2026-06-02
**Audience:** Industry Committee + Technical Commentators — they probe production-readiness, security, engineering maturity.

> Format per question: **Q** · **A** (prepared, ~25s / ≤60 words, spoken) · **Evidence** (file, ADR, or commit so any teammate can switch to the proof in two seconds — see `evidence-checklist.md`).
> Rule of the room: if you don't know, say "we'd verify that against `<artifact>`" — never bluff a number.

---

## Category 1 — Technical (17)

**Q1. Show me the Firestore rules and explain the `diff()` pattern.**
**A:** Each `moods` update is gated by `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` — a field-level allowlist. Even an authenticated owner can only change `mood`, `intensity`, `text`, `mediaRefs`, `updatedAt`. Any other changed key fails the write at the rules layer, before it reaches the database.
**Evidence:** `firebase/firestore.rules:55–69`; helper `isOwner` at `:5–7`.

**Q2. How exactly does the type-level fence prevent Gemini on Tier 3? Walk through the enum.**
**A:** `AiAllowedTier` is an enum of just `one` and `two`. The AI quote method only accepts `AiAllowedTier`, so `Tier.three` cannot be passed. `AiAllowedTier.fromTier(Tier.three)` throws `StateError` by construction — and the dispatcher's Tier-3 branch returns before any AI type is even referenced.
**Evidence:** `ai_allowed_tier.dart:11–27`; dispatcher branch `tiered_intervention_dispatcher.dart:69–73`; test `ai_allowed_tier_test.dart:15–24`; ADR-0012.

**Q3. What's your domain test coverage and how was it measured?**
**A:** Well above our 80% gate — documented per-feature figures run 94.6% to 100%, measured via `flutter test --coverage` into `coverage/lcov.info`. The domain is pure Dart, so it's all unit-testable without a Flutter binding, which is why the number is high organically.
**Evidence:** retro/audit coverage figures in `docs/retros/` + `docs/security/`; gate enforced by `qa-engineer.md:115`.

**Q4. Why Riverpod over Bloc?**
**A:** Riverpod's `@riverpod` codegen gives us compile-time-safe provider graphs, trivial test overrides, and `AsyncValue` to unify loading/error/data without boilerplate. For a five-tab app with heavy per-user family state, it's less ceremony than Bloc for the same safety.
**Evidence:** `CLAUDE.md` stack table (Riverpod 2.x locked); providers in `apps/mobile/lib/features/*/data/providers.dart`.

**Q5. Why Clean Architecture for a team this size — isn't it over-engineering?**
**A:** It's what made the AI orchestration safe. A pure-Dart domain with zero Flutter/Firebase imports means agents can implement and test business rules in isolation, and a commit hook enforces the boundary. The discipline paid for itself the moment we parallelized agents.
**Evidence:** ADR-0001; layer-purity hook in `.claude/hooks/settings.json`.

**Q6. What happens if Firebase Auth goes down?**
**A:** The app is offline-first: reads and writes hit the local Drift database immediately and queue for background sync, so an authenticated session keeps working. A cold sign-in would fail — auth is the one hard online dependency — but existing sessions and local data are unaffected.
**Evidence:** ADR-0004 (Drift offline-first); save flow `mood_repository_impl.dart:297–307`.

**Q7. How do you hit cold start under 2 seconds — where's the proof?**
**A:** We have a committed static performance review — zero HIGH findings — plus a device cold-start runbook for the on-device `--trace-startup` measurement. The one tracked optimization is image caching (`cached_network_image`), which we've scoped but not yet merged. We name it rather than hide it.
**Evidence:** `docs/test-reports/sprint-5-perf-static-review.md` (0 HIGH, 1 MEDIUM = caching) + `sprint-5-cross-platform-runbook.md`; Slide 19.

**Q8. Walk me through one Plan Mode session that produced an ADR.**
**A:** Sprint 5 opened in Plan Mode flagged "highest-stakes — Tier 3 must be byte-for-byte deterministic." That planning conversation is what produced ADR-0012, the type-level Gemini fence. The plan is committed; the ADR is its output.
**Evidence:** `.claude/prompts/sprint-5-kickoff.md:10–13`; `docs/evidence/plan-mode/04-sprint-5-v1-5-release/plan.md`; ADR-0012.

**Q9. How did agents maintain context across sessions? What was the drift mitigation?**
**A:** Three mechanisms: a checked-in `CLAUDE.md` reloaded every session, ADRs as durable decisions, and handoff briefs that pin files and acceptance criteria. When drift happened — like an agent coding an impossible Mann-Kendall tolerance — the human review caught it and we tightened the brief.
**Evidence:** `CLAUDE.md`; `docs/adr/`; `docs/handoffs/HB-007…`; S4 catch in `docs/retros/sprint-4-retro.md`.

**Q10. What's the WebAuthn story? How does origin validation work?**
**A:** WebAuthn passkeys shipped in v1.6 — the client flow is live on web behind the `kEnableWebauthn` build flag. The server validates each assertion against its own configured production origin, never an origin the client claims — that's the anti-spoofing design. The origin is deploy-environment config, not a committed constant.
**Evidence:** ADR-0014; `feature_flags.dart:30` (`kEnableWebauthn = true`); `functions/.../webauthnConstants` (`WEBAUTHN_PRODUCTION_ORIGIN`, server-side). **Presenter caution:** the committed `functions/.env` ships this empty by default — `[CLAUDE_CODE_FILL: confirm the production origin is set in your Firebase deploy env before demoing the live passkey path]`.

**Q11. How does account deletion work end-to-end? Is it GDPR-compliant?**
**A:** A single callable Cloud Function runs an admin-SDK cascade: recursive delete of the user's Firestore subtree, delete of their Storage media, then auth-user deletion — reauth required first. It supports the right-to-erasure; we'd want a formal DPA review before claiming full GDPR certification.
**Evidence:** ADR-0009; `functions/src/wipeUserData.ts`; storage-gap fix commit `c1ca5021`.

**Q12. Are you HIPAA-compliant?**
**A:** No — and that's the correct posture for this product class. MoodBloom is a consumer wellness tool, not a covered medical entity; it stores no PHI from a healthcare provider. We're explicit about it: the app states in five places that it is not a medical device.
**Evidence:** `DisclaimerCopy.full` in `disclaimer_copy.dart:8–12`; disclaimer placements (onboarding, Insights ack, notification footer, Settings).

**Q13. How do you measure mood-score quality? Have you validated against a clinical scale?**
**A:** The mood score is a transparent, deterministic formula — valence times intensity over five — not a learned clinical predictor, so it isn't validated against PHQ-9. The EWMA window is *aligned* to PHQ-9's two-week period by design, but we make no diagnostic claim.
**Evidence:** spec §Mood Score / §EWMA (α=0.15 rationale); ADR-0010.

**Q14. What happens if the Quote Safety Filter has a false negative?**
**A:** It's fail-closed and defense-in-depth: the filter rejects on any forbidden term, over-length, or off-script token, and falls back to a curated phrase on reject *or* network failure. Critically, this path only exists for Tier 1/2 — Tier 3 never touches the filter or Gemini at all.
**Evidence:** HB-008; `quote_safety_filter_impl_test.dart` (TC-41, 55 adversarial inputs, zero pass-throughs); ADR-0012.

**Q15. How does the cooldown survive an app restart? What's the persistence story?**
**A:** The cooldown anchors persist in Firestore at `interventionState/current`, mirrored to local SharedPreferences for offline reads. It's global across tiers and fail-closed — if both reads fail, we block rather than risk a double-notify.
**Evidence:** ADR-0008; `cooldown_guard.dart:35,38,53–56`; HB-007 OQ-B (global).

**Q16. Why is the intervention surface an in-app banner instead of an FCM push?**
**A:** The banner is the primary surface because it's deterministic and visible while the user is in-app; FCM is a secondary channel. This was an explicit open question in the dispatcher brief — we chose banner-plus-FCM, with the banner as the guaranteed path.
**Evidence:** HB-007 "Open questions" OQ-A; `intervention_controller.dart`.

**Q17. How would you deploy to iOS? What's blocking?**
**A:** Nothing architectural — it's one Flutter codebase. iOS was explicitly out of scope for the course (Android + Web), and we removed the iOS scaffold to keep the build matrix honest. Re-adding it is signing certs and an `local_auth`/WebAuthn parity pass, not a rewrite.
**Evidence:** commit `b6c42509` (remove iOS support); `CLAUDE.md` (Android + Web target).

**Q17b. You highlight denormalization but no composite indexes — why, and when would you add them?**
**A:** Our access is per-user, single-collection, and time-ordered, so Firestore's automatic single-field indexes serve every query. We denormalize the weekly garden into one rich document to avoid cross-collection reads. We'd add a composite index only for a multi-field filtered query — e.g. cross-user analytics — which the per-user model deliberately avoids.
**Evidence:** `firebase/firestore.rules` (per-user subtree + denormalized `weeklyGardens.entries[]`); no `firestore.indexes.json` (none needed by design); Slide 18.

---

## Category 2 — Process (8)

**Q18. How long did each sprint take? What was your velocity?**
**A:** Five sprints. Sprint 2 laid the foundation (77 tests), Sprint 3 offline-first + security (294), Sprint 4 the ecosystem redesign / v1.0 (664), Sprint 5 the safety net / v1.5 (1018 at tag) — plus the v1.6 patch wave (responsive redesign + WebAuthn), which is a continuation of Sprint 5, not a sixth sprint. Roughly 4–5 working days each, dispatch-graph driven.
**Evidence:** `docs/retros/sprint-{2,3,4,5}-retro.md`; tag annotations `git tag -n`.

**Q19. What did the AI agents surprise you with — positive and negative?**
**A:** Positive: with a sharp brief, a single agent could land a whole feature, tests included, in one pass. Negative: parallel agents collided on a shared git tree and exhausted rate limits — we learned to isolate them in worktrees and sequence heavy dispatches.
**Evidence:** `docs/retros/sprint-{3,5}-retro.md` (collision + rate-limit notes; six salvage modes codified).

**Q20. What did the agents get wrong that humans caught?**
**A:** Three documented cases: an impossible Mann-Kendall tolerance an integer statistic can't reach; an account-deletion that left Storage media behind; and a brief proposing provider-coupling "for simplicity." All caught in review, none shipped.
**Evidence:** `docs/retros/sprint-4-retro.md`, `sprint-5-retro.md`; fix commit `c1ca5021`; ADR-0011 §Consequences.

**Q21. How did you handle disagreement between an agent's recommendation and human judgement?**
**A:** The human always won, and we recorded why. The clearest case: a brief recommended per-tier cooldowns; the team overrode it to a single global cooldown so a dismissed Tier-1 couldn't surface a jarring Tier-3 the next day. The override lives in the ADR.
**Evidence:** HB-007 OQ-B; ADR-0008/0009.

**Q22. Show me one handoff brief that was wrong on its first version.**
**A:** HB-006's draft merged the atmosphere and plant-tier providers for simplicity. On review we saw it coupled daily weather to weekly health — two different cadences — and revised the brief to keep them separate. Polish later confirmed the split was right.
**Evidence:** `docs/handoffs/HB-006…`; `docs/retros/sprint-4-retro.md`.

**Q23. What's your incident-response plan?**
**A:** Feature flags are the first lever — three Remote Config switches degrade the AI paths safely without a deploy. Crashlytics surfaces the signal; structured logs (no PII) give context. For anything Tier-3-related there's no flag — that path only changes via a reviewed client update, by design.
**Evidence:** Slide 22 rollback table; `main.dart:96` defaults; ADR-0012.

**Q24. How would you onboard a new team member to the multi-agent workflow?**
**A:** Start them on `CLAUDE.md` and the agent definition files — those encode the conventions and the role-separation invariant. Then have them read two ADRs and one handoff brief end-to-end. After that they can write a brief and dispatch within their role's scope.
**Evidence:** `CLAUDE.md`; `.claude/agents/*.md`; `docs/adr/`, `docs/handoffs/`.

**Q25. Did you ever have to roll back a feature flag in development?**
**A:** Yes — the intervention dispatcher shipped dark (`intervention_dispatch_enabled = false`) in v1.0 and we flipped it on only in Sprint 5 once the cooldown and Tier-3 fence were verified. That staged enablement is exactly the rollback lever working in development.
**Evidence:** `feature_flags.dart:60` (default false); ADR-0011; `app/providers.dart:82`.

**Q26. The v1.5 tag says 1018 tests but your slides say 1045 — which is it?**
**A:** Both are true and we can show you. The tag was cut at 1018 on May 19. The executed-evidence run on May 31 captured 1045 Flutter plus 94 Cloud Function tests as v1.6/FCM work landed. We present the logged numbers and footnote the delta.
**Evidence:** `git tag -n` (v1.5 = "1018 tests"); `docs/evidence/platform-execution/flutter-test-vm-host.log` ("+1045: All tests passed!"), `functions-jest.log` (94/94).

---

## Category 3 — Business (6)

**Q27. Who pays for this app? What's the monetization model?**
**A:** Cosmetic-only: tokens earned by showing up unlock flower skins, never therapeutic features. A future model would sell optional cosmetic packs — deliberately *not* a premium currency, paywalled insights, or anything mood-contingent, because that would reintroduce the harm we designed against.
**Evidence:** spec §Token Economy guardrails; `CLAUDE.md` copy rules (no mood-contingent rewards).

**Q28. How do you compete with Daylio, Headspace, and the rest?**
**A:** On the thing they get wrong: they punish lapses and gamify mood. Our differentiator is compassionate-by-construction — plants never die, gamification is mood-agnostic, and the crisis path is deterministic and audited. We compete on retention without manipulation.
**Evidence:** Slides 4–5 (Solution + Competitive Positioning); spec §philosophy + citations (Cheng 2019, Neff 2003).

**Q29. What's the path to v2.0? What's on the roadmap?**
**A:** The v1.6 patch (a continuation of Sprint 5) already shipped the responsive phone/tablet/desktop redesign and lit up WebAuthn passkeys. The remaining tracked items are small — image-cache optimization and one dark-contrast token. Beyond that, v2.0 is iOS parity and a clinician-facing export, neither of which needs an architectural change.
**Evidence:** `docs/evidence/plan-mode/06-v1-6-ui-redesign/plan.md`; `pubspec.yaml` (`google_fonts` — v1.6 redesign); ADR-0014.

**Q30. What's the user-acquisition story? You haven't shipped yet.**
**A:** Correct — we're pre-launch, so this is a plan, not a claim. Entry point is the KMUTT student community where the personas live, with university-counselling partnerships as the trust channel. The product's retention design is the acquisition thesis: word-of-mouth from people who didn't uninstall.
**Evidence:** personas `docs/app-snapshot-for-personas.md`; retention framing Slides 3–4.

**Q31. How would you scale to 100,000 users? Where are the bottlenecks?**
**A:** The client is offline-first, so read load is local. The bottlenecks are Cloud Functions — the Gemini proxy (rate-limited per-uid) and FCM fan-out — and Firestore hot-spots; both scale horizontally. Pattern detection is fully client-side, so the heaviest compute never hits a server.
**Evidence:** ADR-0011 (client-side engine); ADR-0003 (Gemini CF, 10/min/uid rate limit); `functions/src/`.

---

## Coverage check

- **Technical:** 18 (≥15 required) — rules, fence, coverage, Riverpod, Clean Arch, auth-down, perf, Plan Mode→ADR, drift, WebAuthn, deletion/GDPR, HIPAA, mood-score validity, filter false-negative, cooldown persistence, banner-vs-FCM, iOS, indexing/denormalization.
- **Process:** 8 (≥8 required) — velocity, AI surprises, agent mistakes, disagreement, wrong brief, incident response, onboarding, flag rollback. (Q26 = the 1018/1045 reconciliation also lives here.)
- **Business:** 6 (≥5 required) — monetization, competition, v2.0, UA, scale, (implicit market via personas).
- **Total: 32** (≥28 required).

## Hard-question discipline
- Never assert a number you can't tab to. The evidence pointer is the answer's spine.
- a11y and perf are **documented** (sprint-5 a11y report + dark-contrast sweep + perf static review). The only open items are two tracked optimizations — image caching and one dark-contrast token. Name them as such; don't call them "gaps."
- For anything Tier-3: the answer is always "it cannot, by design" — and then the enum.

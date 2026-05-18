# Sprint 5 Demo & Retrospective — v1.5

**Sprint window:** May 13 – May 19, 2026 (5 working days)
**Demo date:** May 19, 2026
**Release tag:** `v1.5` (local tag on `feat/s5-v1.5-final`, head `977b86d3`); push pending the manual cross-platform run
**Team:** Kraiwich Jaiton, Teerin Kittichaicharoen, Theerawat Patthawee (Lead), Jedsarit Fanpimiy, Napat Chang-ekwong

---

## 1. What we shipped (v1.5)

Sprint 5 wires the safety net live. The Pattern Engine from Sprint 4 emits `Tier?` triggers; in v1.0 they fired only internally. In v1.5 those triggers surface as Tiered Intervention notifications, route to user-facing screens, and respect both cooldown and per-tier opt-outs.

| WBS | Feature | Commit on `feat/s5-v1.5-final` |
|---|---|---|
| 5.4 | Tiered Intervention dispatcher + `CooldownGuard` + 3 tier screens (Breathing, Journaling, Crisis) + banner | `cb8946f3` → `af54ad63` → `988aaf03` |
| 5.5 | Quote Library + curated pools (Tier 1/2/3) + `QuoteSafetyFilter` + `suggestQuote.ts` CF | `cd633205` |
| 5.6 | Insights screen + mandatory disclaimer ack on first view | `8965c2a3` |
| 6.3 | Flower skin system — domain + data + modal + per-flower detail | `a87a347d` (merged via `ed2cd755`) |
| 7.3 | Per-tier FCM toggles in Settings + migration from legacy `cheerUpEnabled` | `5914f99f` |
| 7.4 | Bipolar/medical Disclaimer Service — footer on every notification, ack dialog on first Insights view, Settings restate | (folded into 5.4 + 5.6 + intervention screens) |
| 2.4 | Account deletion — reauth fence → admin-SDK cascade → `auth.deleteUser` → signOut | `cb2f623c` + `c1ca5021` (Storage drain fix) |
| 8.3 | Integration tests — login, mood, AI override, harvest, all 3 tiers (TC-40 end-to-end) | `449acdd9` |
| 8.4 | A11y sweep + dark-mode contrast sweep + cross-platform runbook | `d7728d8b`, `f38408c1`, `2dd6362f`, `77ade6e7` |
| 9.1 | Enterprise Security Posture Report (final, GO with three conditions) | `626c8c3e` |

Plus six polish waves (A: hitbox + customize visibility + debug token tile + rule TODO cleanup; B: responsive sheets for desktop; D: HB-009 Patterns/Insights redesign; E: ADR-0013 biometric gating + PIN fallback; C: dark-mode contrast sweep; plant-impact tier differentiation), then a WebAuthn foundation per ADR-0014 (shipped dark), three follow-up fixes (debug retrigger, capsule-shaped flower hitbox, WebAuthn Settings tile), and a "Take a breath" CTA on the garden summary row.

Eight architecture decisions accepted this sprint: ADR-0008 (cooldown persistence), ADR-0009 (account-deletion topology), ADR-0012 (Tier 3 determinism + Gemini-mock test), ADR-0013 (biometric gating + PIN fallback), ADR-0014 (WebAuthn dark-ship rationale). Three handoff briefs filed: HB-007 (Tiered Intervention dispatcher), HB-008 (Quote Library + Safety Filter), HB-009 (Patterns/Insights redesign).

## 2. Demo flow on May 19

1. Open Settings → Debug → "Trigger Tier 1 banner (debug)" → banner appears with a Gemini-suggested phrase that has been filtered through `QuoteSafetyFilter`, plus the disclaimer footer "MoodBloom is not a medical device. Not a substitute for professional care." (TC-38).
2. Tap "Open" → the 2-minute breathing screen renders with a 4-second-in / 6-second-out animated circle and a visible mm:ss countdown. Tap "I'm okay" → opt-out records, cooldown anchor advances (TC-34).
3. Advance to Tier 2 via the debug tile → journaling prompt screen with a rotating curated question; type a few words; Save invokes `SaveMoodEntryUseCase`.
4. Advance to Tier 3 via the debug tile → crisis-resources screen renders the **byte-for-byte curated** message (no Gemini call possible) plus the Hotline 1323 tile + 3 resource cards (TC-33). The back gesture is intercepted with a "Are you sure?" confirmation (defence-in-depth).
5. First-time tap on Patterns → "Open detailed insights" CTA → Insights screen displays the mandatory ack dialog with `DisclaimerCopy.full`. Tap "I understand" → chart renders with the 5 tier bands + persistent legend + recent-triggers list (TC-36, TC-37).
6. Settings → Account → Delete → reauth → CF cascade deletes Firestore + Storage media + rate-limit docs → client-side `auth.deleteUser` → app returns to onboarding.
7. The new garden summary row shows the five tier states via the tier pill (Flourishing / Thriving / Resting / Weathering / Storm Season) plus a "Take a breath" pill that routes the user to the breathing screen on demand (not only when Tier 1 fires).

## 3. Test results — TC-40 + TC-41

**TC-40 (Tier 3 must never call Gemini)** is the highest-stakes test in the project. ADR-0012 defends it at five layers:

1. **Type fence** — `AiAllowedTier { one, two }` enum cannot represent `Tier.three`. `AIQuoteRepository.requestSuggestion` accepts `AiAllowedTier`, not `Tier`. See `apps/mobile/lib/features/intervention/domain/entities/ai_allowed_tier.dart`.
2. **Dispatcher hard branch** — `TieredInterventionDispatcher.dispatch` switches on `tier`; the `Tier.three` arm goes directly to `QuoteLibrary.pickTier3` and returns before any AI-adjacent type is referenced. See `tiered_intervention_dispatcher.dart:63-102`.
3. **Unit test** — `tiered_intervention_dispatcher_test.dart` asserts `recordingFake.calls.isEmpty` for every Tier 3 dispatch path, unconditionally.
4. **Controller test** — `intervention_controller_test.dart:387-424` re-asserts at the controller layer.
5. **Integration test (NEW)** — `integration_test/intervention_tier_3_test.dart:151-162` exercises the full app with the production controller, dispatcher, library, and safety filter; only the AI repo is the recording fake; asserts `aiRepo.calls.isEmpty` after a Tier 3 dispatch with the reason quoting ADR-0012.

A sixth layer exists at the server boundary: `functions/src/suggestQuote.ts` rejects `tier: 3` with `HttpsError('invalid-argument')` before any Gemini SDK call. The PII canary test asserts `generateContentMock` is never invoked on Tier 3.

**TC-41 (Quote Safety Filter rejection rate)** ran a 55-input fuzz against `QuoteSafetyFilterImpl.gate` — 25 forbidden-word inputs (one per blacklist entry: depression, anxiety disorder, bipolar, diagnose, medication, prescribe, therapy, must, should, now, have to, need to, fix yourself, get better, overcome), 15 over-length inputs (>140 chars), 10 off-script inputs (low whitelist overlap), 5 "almost-OK" trick inputs (single forbidden word embedded in valid phrasing). **100% rejection. Zero pass-throughs.** Five known-good curated phrases were also pumped through as positive controls — all passed the filter.

Tip-of-branch verification at `977b86d3`:

- `flutter test`: **1018 / 1018 passed** (after the user-requested ~10% trim of golden + duplicate-a11y tests).
- `flutter analyze`: clean (0 errors, 0 warnings; 37 pre-existing `hasFlag` info-level deprecations from earlier a11y tests).
- `npm test` from `functions/`: 73 / 73 passed across 5 suites (`analyzeMoodText`, `suggestQuote`, `wipeUserData`, `analyzePatterns`, `sendCheerUpPush`).
- Domain layer coverage on `apps/mobile/lib/features/*/domain/`: unchanged from S4 (no domain tests removed in the trim) — every feature ≥80%, overall 94.6%.

## 4. Bipolar disclaimer compliance (TC-36 .. TC-39)

- **TC-36** — first Insights view shows the mandatory non-dismissible ack dialog. Verified by `insights_screen_test.dart:181-208`. The dialog is `barrierDismissible: false` and the back gesture is suppressed; only the "I understand" button can pop it.
- **TC-37** — ack state persists across restarts via the polish-era `users/{uid}.insightsDisclaimerAcked` boolean (`firestore.rules` enforces a one-way `false → true` transition).
- **TC-38** — every Tier 1/2/3 notification body contains `DisclaimerCopy.notificationFooter` as a substring. The dispatcher composes `body = quote + "\n\n" + footer`. Verified at every of the five Tier 3 fence layers and at `intervention_dispatch_test.dart`.
- **TC-39** — Settings → About contains the full disclaimer text verbatim (verified by the a11y sweep's `disclaimer_ack_dialog_a11y_test.dart`).

## 5. Cross-platform parity

Documented in `docs/test-reports/sprint-5-cross-platform-runbook.md`. The runbook describes the Android emulator (Pixel 6 API 34) + Chrome web matrix: 18 integration tests via `flutter drive`, manual demo script, screenshot inventory, cold-start measurement, frame-rate trace, memory-growth check over 50 entries.

**Execution status: pending.** The runbook is the manual gate before the `v1.5` push. The reports cite it as the evidence trail; the team executes before the May 19 submission window.

## 6. A11y sweep

Two reports filed: `docs/test-reports/sprint-5-a11y-report.md` (light theme + 200% type) and `docs/test-reports/sprint-5-dark-mode-contrast-report.md` (dark theme). 22 + 53 = 75 a11y tests pass on the final branch; the latter file's spreadsheet covered 16 token pairs × 2 themes = 32 contrast measurements.

**One known LOW failure:** `mb.textDim` over `mb.softCoral` measured **4.38:1 on light theme** (WCAG AA threshold 4.5:1) — a cosmetic affordance hint, not load-bearing text. Fixed in commit `b864e438` by promoting the price text in `LockedSkinChip` back to `mb.text` and communicating the unaffordable state via icon and border opacity only. Re-measurement post-fix: ≥4.5:1 on both themes.

Disclaimer ack dialog readability at 200% type was the explicit checkpoint in the Sprint 5 plan; passed on every tested surface after the `scrollable: true` fix in commit `d7728d8b`.

## 7. Performance profile

Static review committed in `docs/test-reports/sprint-5-perf-static-review.md`:
- All `ListView(...)` callsites on the S5 + carryover surface load fixed children (≤6 items typical). Enterprise R4 "no unbounded `ListView`" gate satisfied by inspection.
- `MoodScoreLineChart` caps at 30 data points (Insights's longest window); `fl_chart`'s `LineChart` painter is well within a single frame budget.
- One LOW finding (P-L01): the breathing screen's `AnimatedBuilder` rebuilds the cue text at 60fps. Device profile will confirm whether it matters; deferred to v1.6 pending the runbook execution.

**Device-side measurements pending** the runbook execution (cold-start <2s mid-range Android; Insights scroll frame rate; memory across 50-entry harvest cycle).

## 8. What went well

- **The Tier 3 fence held.** ADR-0012's type-system-plus-three-test-layers design was paranoid but correct. Adding the integration-test layer in Sprint 5 was a one-day investment that catches any future refactor at PR review.
- **The Safety Filter shipped fail-closed.** TC-41's 100% rejection across 55 adversarial inputs (with five positive-control passes) is the kind of bright-line correctness result that makes a v1.5 release credible to a clinical reviewer.
- **The polish track absorbed five real user complaints without slipping the tag.** Sheets are responsive on desktop; the customize button is visible; the debug-token tile lets QA grant balance without the daily cap; the round-then-capsule hitbox addresses the "small target with offset" gripe; the plant-impact tier pill answers "I can't tell which state I'm in." Each fix shipped same-week.
- **The WebAuthn foundation went in dark.** ADR-0014 committed the architect to a build-time flag, a server-side provisioning guard, and a PIN dependency. The flag stays false in v1.5; the foundation is auditable; v1.5.1 lights it up once a production origin is decided.

## 9. What was hard

- **Six dispatch salvages in one sprint.** Memory `[[workflow_parallel_agent_dispatch]]` now logs six failure modes — work-in-orchestrator-cwd, agent-doesn't-commit, wrong-base-branch, rate-limit-mid-task, socket-error-mid-task, work-in-worktree-but-uncommitted. Each cost 10–30 minutes of orchestrator salvage. The playbook is now codified but the cost was real.
- **Codegen + LF/CRLF noise.** Every Freezed/Riverpod regeneration after a salvage flagged ~40 `.freezed.dart` / `.g.dart` files as modified for line-ending normalization. Every commit had to filter the noise. Tooling improvement for v1.6: a pre-commit hook that auto-discards generated-file LF/CRLF-only diffs.
- **The user-testing pass surfaced four real gaps the agents missed.** See section 11.
- **Cross-platform run is still pending.** The runbook is documented, but `flutter drive -d emulator-5554` has not been executed at write time. The v1.5 tag was applied locally; the push is gated on the runbook completing green.

## 10. What the human team caught that the agents missed

- **Skin-system widget tests deferred.** The Day-1 skin agent shipped 53 token tests including TC-9/TC-10 unit coverage, but the dispatcher had errored mid-run before writing widget-level TC-6/7/8. The orchestrator salvaged ~1700 lines from the wrong worktree path and committed it as a partial; a follow-up agent landed the widget tests next session.
- **WebAuthn settings tile not surfaced.** The architect's ADR-0014 deferred the UI tile to v1.5.1 with the foundation marked complete; the user asked "why isn't it wired in the settings page?" within five minutes of opening v1.5. The tile now ships in v1.5 in a state-aware "v1.5.1 preview" disabled-mode by default, with proper enabled-mode wiring for when the build-time flag flips.
- **Debug Tier triggers fired only once.** The first implementation routed `debugDispatch` through `DispatchInterventionUseCase`, which includes the `CooldownGuard`. After opt-out (which advances the cooldown anchor), every subsequent debug call silently returned `Err(cooldown)`. Fix: bypass the use case for the debug path and call the dispatcher directly. ADR-0012's Tier 3 fence is preserved.
- **Flower hitbox too small + offset.** A 48–64 dp circle centred at 35% bed height worked in theory but missed the bloom on tall species (sunflower) AND on short species (forget-me-not). The user reported "too small and a lot of offset." Fix: replace circle with a `StadiumBorder` capsule that hugs the full plant silhouette (48–72 dp × 85% bed height) — bigger tap area, position-agnostic across species.

## 11. Going into v1.5.1

Three items defer to v1.5.1 (or v1.6 per ADR-0014's roadmap):

- **WebAuthn lit up** — the three remaining CFs (`webauthnRegisterFinish`, `webauthnAssertionStart`, `webauthnAssertionFinish`), the Firestore rules block, the JS-interop invocation from the UI tile, the Jest test suite. Gated on a production origin being decided.
- **Cross-platform runbook executed** — Android emulator + Chrome web integration runs, cold-start measurement, frame-rate trace, memory growth check. The runbook is in `docs/test-reports/sprint-5-cross-platform-runbook.md`.
- **Device-side performance baseline** — the static review covers `ListView` and chart-budget invariants; cold-start <2s on mid-range Android still needs the device-side trace to confirm.

The Sprint 5 final Security Posture Report (`docs/security/sprint-5-final-posture-report.md`) is **GO with three conditions**: file D-M01 (transitive `pnpm audit` HIGH advisories — `fast-xml-builder`, `fast-uri`) as a v1.6 ticket; decide on the skin-system branch posture (now merged into `feat/s5-v1.5-final`); and confirm the cross-platform runbook's done-criteria checklist on Android + Chrome.

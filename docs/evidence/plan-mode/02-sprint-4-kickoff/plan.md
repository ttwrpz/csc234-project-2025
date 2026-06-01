# Sprint 4 - v1.0: Compassionate Reframing + Pattern Analysis + Test Suite

**Window:** 2026-05-06 → 2026-05-12 (Day 1 = Wed May 6, Day 5 = Tue May 12). **Release target:** tag `v1.0` after the May 12 demo.

---

## Context

S3 shipped `v0.3-beta`: Gemini single-entry classifier, Drift offline-first, Firestore rules with emulator coverage, biometric gate, line chart, calendar, ≥80% domain coverage. Six of seven pivot features have at least a stub. **Negative-mood visualisation, pattern analysis (Cloud Function + UI), pattern detector, dark mode, and the widget+golden+integration test layer are all unbuilt.**

Sprint 4 closes that gap so the app can ship as v1.0. Only the cheer-up intervention UI itself (S5) remains after this. Two highest-risk items: Gemini-powered pattern analysis (non-determinism vs. graded demo) and rain-cloud animation (continuous animation vs. deterministic goldens). Team is at capacity - favour mechanical reuse of S3 patterns over fresh design.

Acceptance bar (from kickoff): negative i1–3 wilts, i4–5 rains; rain self-fades 15–25s; ≥1 Pattern Insight with confidence label visible; flag flip hides Insights within 60s; dark mode works; ≥6 widget tests; ≥6 goldens; integration test for login on Android **and** Chrome.

---

## Dependency shape

```mermaid
graph TD
  A[Day 1: ADR-0006 + ADR-0007 + Pattern brief] --> B[Day 1: Wilting widget]
  A --> C[Day 1: Dark theme tokens + buildDarkTheme]
  A --> D[Day 1: pumpApp + golden_toolkit setup]
  A --> R0[Day 1: SDK-bump regression run on analyzeMoodText]

  B --> E[Day 2: Rain cloud widget + GardenCanvas per-entry render]
  C --> F[Day 2: themeModeController + extract SettingsScreen + bootstrap wiring]
  D --> G[Day 2: 4 existing-widget goldens + 2 garden goldens]

  R0 --> H[Day 3: analyzePatterns Cloud Function]
  H --> I[Day 3: security-reviewer audit Cloud Function]
  H --> J[Day 3: client datasource + repo extension + PatternInsightCard]
  E --> K[Day 3: Garden goldens unskip wilt+rain]
  G --> L[Day 3: AnalyticsScreen widget test + golden]

  J --> M[Day 4: PatternInsightCard polish + 4 confidence goldens]
  J -. derives detector inputs .-> N[Day 3-4: pattern_detector.dart pure function + storage]
  N --> O[Day 4: interventionStateProvider wiring (no UI)]
  M --> P[Day 4: Runbook + RC kill-switch rehearsal]

  O --> Q[Day 4: integration_test/ harness + auth flow]
  Q --> S[Day 5: Settings widget test + dark golden]
  S --> T[Day 5: Tag v1.0 + security posture report]
```

The vertical critical path is `Cloud Function → datasource → card → kill-switch rehearsal → tag`. Garden visuals and dark mode are parallel tracks. Goldens trail their widgets by 1 day so the silhouette is settled before baselining.

---

## Backlog → owner → anchor file

| WBS | Item | Owner | Anchor file |
|---|---|---|---|
| 4.2 | Wilting plant (neg i1–3) | Napat | `apps/mobile/lib/features/garden/presentation/widgets/wilting_plant.dart` (NEW) |
| 4.3 | Rain cloud + self-fade (neg i4–5) | Napat | `apps/mobile/lib/features/garden/presentation/widgets/rain_cloud.dart` (NEW) |
| 5.3 | `analyzePatterns` CF + Insights UI + RC gate | Kraiwich + security-reviewer | `functions/src/analyzePatterns.ts` (NEW), `pattern_insight_card.dart` (NEW) |
| 5.4 | Pattern detector + cooldown + escalation | Kraiwich | `apps/mobile/lib/features/garden/domain/pattern_detector.dart` (NEW) |
| 6.2 | Dark mode toggle | Teerin | `packages/design_system/lib/src/theme.dart` + extracted `SettingsScreen` |
| 7.2 | Widget + golden tests | Jedsarit (qa) | `apps/mobile/test/goldens/**`, `test/helpers/pump_app.dart` (NEW) |
| 7.3 | Integration tests | Jedsarit (qa) | `apps/mobile/integration_test/**` (NEW) |
| Cross | RC consumer wiring | Kraiwich | extend `AIAnalysisRepository` |
| 8.1 | Enterprise Audit draft | Theerawat | `docs/reports/enterprise-audit-v1.md` (NEW) |

**Out of scope (do NOT start):** cheer-up banner, FCM notifications, hotline 1323 footer, breathing screen, account deletion, full a11y sweep, perf profile.

---

## Verified existing surface (do not re-explore)

- `DayBloomKind { bloom, empty }` at `apps/mobile/lib/features/garden/domain/entities/garden_state.dart:54` with TODO comment for `wilting`/`rainCloud`. `GardenState` has only `positiveMoodCount`, `currentStreakDays`, `last7Days[7]`.
- `ComputeGardenStateUseCase` (pure Dart) buckets only positives; `_atMidnightLocal` static helper at `compute_garden_state.dart:70`.
- `MoodEntry.intensity:int` (1..5 validated). `MoodType.category` returns `MoodCategory { positive, negativeMild, negativeStrong }`.
- `functions/src/analyzeMoodText.ts` is the canonical CF pattern: `onCall({region:'asia-southeast1', secrets:[GEMINI_API_KEY], timeoutSeconds:30, memory:'256MiB', enforceAppCheck:false})`, throws `HttpsError('unauthenticated')`, Firestore-tx rate-limit 10/60s, 5s `AbortController` on Gemini, structured log line. Reuses `geminiClient.ts`, `rateLimit.ts`, `types.ts`. `index.ts:3` already TODOs `analyzePatterns`.
- **`functions/package.json` has uncommitted SDK bumps** (`@google/generative-ai ^0.24.1`, `firebase-admin ^13.8.0`, `firebase-functions ^7.2.5`, Node `^20 || ^24`). Day-1 task: run existing `analyzeMoodText.test.ts` against the bumped SDK before stacking new code.
- `AnalyticsScreen` (`apps/mobile/lib/features/analytics/presentation/analytics_screen.dart`) build column children: `[MoodWindowSelector, Expanded(_ChartBody), _Legend]`. The Insights card slots between `Expanded(_ChartBody)` and `_Legend`.
- `AIAnalysisRepository` at `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` has only `analyzeMoodText`. No `isEnabled` getter, no `analyzePatterns`.
- Remote Config wired in S3: sync `featureFlagsProvider` at `apps/mobile/lib/app/providers.dart:72-84` exposes `FeatureFlags { aiPatternAnalysisEnabled, geminiDetectionEnabled }`. Defaults registered in `main.dart:48-60` (60min min-fetch interval). **Only the consumer wiring at the Insights card is missing.**
- **Settings screen exists in-file** as private `_SettingsScreen` at `apps/mobile/lib/app/router.dart:221-271`. Wired to `/settings` route, bottom-nav index 4. Has account row, Sign-out, `BiometricSettingsTile`, debug crash button. Plan: extract to `features/settings/presentation/settings_screen.dart` and add Appearance section. **No new route, no nav-bar surgery.**
- `buildLightTheme()` only at `packages/design_system/lib/src/theme.dart`. `MoodBloomColors.seedDark` defined but unused. `apps/mobile/lib/app/theme.dart` re-exports `buildLightTheme`. `bootstrap.dart` `MaterialApp.router` has no `darkTheme`/`themeMode`.
- `compute_analytics_state.dart:89` has identical `_localMidnight` static helper. Both `compute_garden_state` and `compute_analytics_state` should migrate to a single helper in `packages/core`.
- `firebase/firestore.rules` already permits `users/{uid}/insights/{id}` read for owner, write for admin SDK only (S3 anticipated S4). No rule changes needed for 5.3.
- Tests: 47 files under `apps/mobile/test/`. Hand-rolled fakes in `test/features/*/domain/fakes/`. **No `pumpApp`, no `golden_toolkit`, no `goldens/`, no `integration_test/`.** CI runs plain `flutter test` on Linux.

---

## Day-by-day plan

### Day 1 - Wed May 6

**architect**
- Write **ADR-0006 - Compassionate reframing** at `docs/adr/0006-compassionate-reframing.md`. Decisions: (a) reframing splits on intensity within negatives, not on `MoodCategory` - `kind(m,i) = m.category==positive ? bloom : (i<=3 ? wilting : rainCloud)`; (b) extend the existing enum (no sealed class - keeps `DayBloomKind` presentation-free); (c) day priority `bloom > rainCloud > wilting > empty`; (d) rain-cloud fade is ephemeral, deterministic per-entry-id, not persisted; (e) wilting silhouette differs from flower by **shape**, not colour (drooping stem) so grayscale goldens distinguish them.
- Write **ADR-0007 - Pattern analysis fallback** at `docs/adr/0007-pattern-analysis-fallback.md`. Decision: statistical-primary, Gemini-supplementary. Always compute deterministic insights server-side (weekday z-score, current 3-day intensity-≥4 streak, 30-day least-squares trend); call Gemini once for an optional themes insight; Gemini failure is non-fatal. PII fence: request schema is Zod `.strict()` with **no `text` field**; client datasource projection drops `text` and `mediaRefs` (asserted in unit test). Confidence bands: low <0.5 outline yellow, mid [0.5,0.8] filled default, high >0.8 filled primary; sample-size floor of 10 clamps confidence to ≤0.5 server-side AND defensively client-side.
- Drop a Pattern Detection handoff brief in `.claude/briefs/sprint-4/pattern-detection.md` referencing the file list in this plan.

**flutter-engineer (Napat) - WBS 4.2**
1. Edit `apps/mobile/lib/features/garden/domain/entities/garden_state.dart`: extend `enum DayBloomKind { bloom, empty, wilting, rainCloud }`. Add `wiltingMoodCount: int` and `rainCloudMoodCount: int` to `GardenState`. Update `isEmpty` → all three counts == 0.
2. Edit `apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart`: replace single `positiveDays` with three Sets bucketed by `kind(m,i)`. Day-aggregation priority for `last7Days` cells: `bloom > rainCloud > wilting > empty`.
3. Run `cd apps/mobile && flutter pub run build_runner build --delete-conflicting-outputs` to regenerate freezed.
4. Build `WiltingPlant` (`StatelessWidget`): `Transform.rotate` (~25°) wrapping `Icon(Icons.spa, color: MoodBloomColors.moodSad)` plus a downward `CustomPaint` arc for the drooping stem. Decorative; `ExcludeSemantics`.

**flutter-engineer (Teerin) - WBS 6.2 (parallel; no file collisions with Napat)**
1. Edit `packages/design_system/lib/src/tokens/colors.dart`: add `surfaceCreamDark`, `surfaceDimDark`, `outlineDark`, `onSurfaceDark`, `onSurfaceMutedDark`. Annotate the mood palette `// TODO(S5-a11y): tune mood-* for dark contrast`.
2. Edit `packages/design_system/lib/src/theme.dart`: add `buildDarkTheme()` mirroring `buildLightTheme()` with `ColorScheme.fromSeed(seedColor: MoodBloomColors.seedDark, brightness: Brightness.dark, surface: surfaceCreamDark)`.
3. Re-export `buildDarkTheme` in `packages/design_system/lib/design_system.dart` and `apps/mobile/lib/app/theme.dart`.

**qa-engineer - WBS 7.2 foundation**
1. Add `golden_toolkit: ^0.15.0` to `apps/mobile/pubspec.yaml` dev_dependencies.
2. NEW `apps/mobile/test/helpers/pump_app.dart` with `pumpApp(WidgetTester, {required Widget child, List<Override> overrides = const [], ThemeMode themeMode = ThemeMode.light})`. Wraps `ProviderScope` + `MaterialApp(theme: buildLightTheme(), darkTheme: buildDarkTheme(), themeMode: themeMode, home: child)`. **Do not migrate** the existing `_pumpSignIn` / `_pumpLogMood` helpers in S4 - note as S5 follow-up.
3. NEW `apps/mobile/test/flutter_test_config.dart` calling `loadAppFonts()`.
4. NEW `apps/mobile/dart_test.yaml` with `tags: { golden: { } }`.
5. Pre-compute goldens for already-shipped widgets independent of S4 work: SignIn, LogMood, IntensitySlider, History (4 goldens).

**flutter-engineer (assigned) - SDK regression**
- Run `cd functions && npm ci && npm test` after the SDK bumps to confirm S3's 14-case `analyzeMoodText` suite still passes. Block Day-3 work if it doesn't.

**security-reviewer** idle today. Pre-read ADR-0007 outline once it lands.

---

### Day 2 - Thu May 7

**flutter-engineer (Napat) - WBS 4.3**
1. Build `RainCloud` (`StatefulWidget` with `final String entryId; final double size; @visibleForTesting final bool animate = true;`). `initState` builds `AnimationController(duration: Duration(milliseconds: 15000 + (entryId.hashCode.abs() % 11) * 1000))` → 15–25s deterministic per entry id. `Tween<double>(begin:1.0, end:0.0)` ease-out. Glyph: `Icon(Icons.cloud, color: MoodBloomColors.moodAnxious)` plus three rain-streak `Container`s in a `Stack`. `dispose` closes the controller.
2. Edit `apps/mobile/lib/features/garden/presentation/garden_screen.dart` `_GardenCanvas` to render per-entry glyphs by `DayBloomKind` (today the canvas only loops `flowerCount` indices, not entries - switch to iterating `state.last7Days`-resolved entries / passed-in lists). Cap visible animating clouds at 5; stagger start by `i*200ms`. Update Semantics aggregate label: `"Garden, N positive moods, M gentler days, K stormy days drifting away"`.
3. Wire RC consumer: extend `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` with `bool get isEnabled` (reads `featureFlagsProvider.aiPatternAnalysisEnabled` indirectly via the impl's flags ref) AND `Future<Result<List<PatternInsight>, AiAnalysisFailure>> analyzePatterns({required List<MoodEntry> history, int windowDays = 90})`. Implementation lands Day 3.

**flutter-engineer (Teerin) - WBS 6.2**
1. NEW `apps/mobile/lib/features/settings/data/theme_mode_storage.dart`: thin SharedPreferences wrapper, key `settings.theme_mode`, values `system|light|dark`.
2. NEW `apps/mobile/lib/features/settings/presentation/controllers/theme_mode_controller.dart`: `AsyncNotifier<ThemeMode>` (riverpod_generator), reads from storage, default `ThemeMode.system`, mutator `setMode(ThemeMode)`.
3. **Eager-resolve in `apps/mobile/lib/main.dart`**: `await SharedPreferences.getInstance()` before `runApp`, seed the controller via override on `ProviderScope` so the dark mode preference is hot before first frame (no flash-of-light).
4. Edit `apps/mobile/lib/app/bootstrap.dart` `MaterialApp.router`: `darkTheme: buildDarkTheme()`, `themeMode: ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system`.
5. **Extract `_SettingsScreen`** from `router.dart:221-271` to NEW `apps/mobile/lib/features/settings/presentation/settings_screen.dart` as public `SettingsScreen`. Update `router.dart` import. **Preserve all existing tiles** (account row, divider, Sign-out, BiometricSettingsTile, debug crash). Add an "Appearance" section ABOVE account with a `DropdownButton<ThemeMode>` bound to `themeModeControllerProvider` (System / Light / Dark). All new code uses `Theme.of(context).colorScheme.*` - no direct `MoodBloomColors.surfaceCream` references in the Appearance section.

**qa-engineer**
1. Quick audit (`Grep "MoodBloomColors\."`): there are ~48 hits across `apps/mobile/lib`, mostly in `calendar_view.dart`, `entry_detail_screen.dart`, `mood_entry_tile.dart`, `weekly_bloom_bar.dart`, `garden_screen.dart`. File S5 follow-up tickets; **do NOT block dark-mode acceptance on a full rebalance** - kickoff acceptance reads "every screen respects it", which is satisfied by `MaterialApp.themeMode` switching the `ColorScheme`. Token rebalance is the S5 a11y sweep.
2. Garden goldens for shippable states today: `empty` + `flower` (2 goldens). Pre-stage `garden_screen.golden_test.dart` with `wilting` + `rainCloud` cases skipped - unskip Day 3.
3. Architect reviews wilting + rain-cloud widgets against US-Som-1 ("no user action to clean up a rain cloud"). Sign-off needed before goldens are baselined.

---

### Day 3 - Fri May 8

**flutter-engineer (Kraiwich, AM) - WBS 5.3 server**
1. NEW `functions/src/analyzePatterns.ts` mirroring `analyzeMoodText.ts`. `onCall` config: `region:'asia-southeast1'`, `secrets:[GEMINI_API_KEY]`, `timeoutSeconds:30`, `memory:'256MiB'`, **`enforceAppCheck:true`** (stricter than `analyzeMoodText`'s `false` - see Open Question O-1).
2. Edit `functions/src/rateLimit.ts`: parameterise `consumeToken(uid, nowMs?, opts?: {windowMs, max})` with current values as defaults so `analyzeMoodText` is byte-identical. `analyzePatterns` calls with `{windowMs:30_000, max:1}`.
3. Edit `functions/src/types.ts`: add `AnalyzePatternsRequestSchema` (Zod **`.strict()` - no `text` field**), `PatternInsight`, `AnalyzePatternsSuccess`/`Error` shapes. Schema:
   ```ts
   AnalyzePatternsRequestSchema = z.object({
     requestId: z.string().uuid(),
     v: z.literal(1),
     windowDays: z.number().int().min(7).max(180),
     history: z.array(z.object({
       date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
       moodCode: z.enum(MOOD_TYPES),
       intensity: z.number().int().min(1).max(5),
     })).max(500),
   }).strict();
   ```
4. Validation order (mirror `analyzeMoodText`): auth → Zod → rate-limit → statistical compute (always, deterministic) → Gemini call (optional, 5s abort) → respond. Insight kinds: `weekday`, `streak`, `trend`, `gemini`. Statistical computations defined in ADR-0007.
5. Edit `functions/src/index.ts`: `export { analyzePatterns } from './analyzePatterns.js';`.
6. NEW `functions/src/__tests__/analyzePatterns.test.ts`: 10 cases including auth, Zod-strict reject of `text` field, rate-limit, statistical-only happy path (Gemini disabled), Gemini-success enrich, Gemini-timeout fallthrough, Gemini-malformed fallthrough, sample-size floor clamp, **PII canary** (assert no `history[].date` and no `insight.text` content appear in any captured `loggerCalls` payload).

**security-reviewer (PM Day 3)** audit checklist for `analyzePatterns.ts`:
- Zod `.strict()` rejects unknown keys.
- No `mood.text` projection on the client side (audit `analyze_patterns_functions_datasource.dart`).
- Rate-limit `consumeToken` call is in the right order and uses the new opts.
- `enforceAppCheck:true` is set.
- Logs contain `insightCount`, `geminiSkipped`, `geminiSkipReason` only - no PII.

**flutter-engineer (Kraiwich, PM) - WBS 5.3 client**
1. NEW `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart` (Freezed): `id, text, confidence, sampleSize, generatedAt, kind: PatternInsightKind { weekday, streak, trend, gemini }`.
2. NEW `apps/mobile/lib/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart` cloning `ai_analysis_functions_datasource.dart`. **Hard rule:** the projection MUST drop `text` and `mediaRefs` from each `MoodEntry`. Assert in unit test `expect(projected[0].containsKey('text'), isFalse)`.
3. Extend `apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart` with `analyzePatterns` (do NOT spawn a sibling repo - keeps the AI surface coherent). `isEnabled` returns the `featureFlagsProvider` value injected at construction.
4. NEW `apps/mobile/lib/features/analytics/presentation/widgets/pattern_insight_card.dart` (`ConsumerWidget`). First check `featureFlagsProvider.aiPatternAnalysisEnabled` - return `SizedBox.shrink()` when `false`. When enabled, watch a new `patternInsightsProvider` (FutureProvider keyed on the current `MoodWindow`). Five UI states: loading (skeleton), error (`"We couldn't read your patterns just now"`), empty (`"Log a few more moods to see patterns"`), data (rows with confidence chip + `"$n samples"` badge), disabled (hidden).
5. Edit `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart`: insert `const PatternInsightCard()` between `Expanded(_ChartBody)` and `_Legend`. Wrap the **insertion** in `if (ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled)` for defence in depth (the widget self-hides too).
6. **Lock copy templates at this PR** (per Open Question O-2): `"Your <weekday> mood averages X.X lower than the rest of the week"`, `"Your mood has been trending [up|down] over the past 30 days"`. UX writer reviews post-merge.

**flutter-engineer (Kraiwich, late PM, parallel) - WBS 5.4 detector**
1. NEW `packages/core/lib/src/date_utils.dart` exporting `DateTime localMidnight(DateTime dt)`. Migrate `compute_garden_state.dart:70` AND `compute_analytics_state.dart:89` to use it (they have identical helpers today). Pure-Dart, no new package deps. Re-export from `packages/core/lib/core.dart`.
2. NEW `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart` (Freezed): `bool triggered, bool escalated, String reason` (e.g. `'5_of_7_negative'`, `'3_consecutive_high_intensity'`, `'cooldown'`, `'none'`).
3. NEW `apps/mobile/lib/features/garden/domain/pattern_detector.dart`: pure function
   ```dart
   InterventionState detectPattern(
     List<MoodEntry> entries, {
     required DateTime now,
     DateTime? lastTriggeredAt,
     DateTime? firstTriggeredAt,
   });
   ```
   Rules:
   - **5-of-7 days**: count distinct local-midnight days in last 7 with ≥1 entry where `mood.category != positive`. Trigger if count ≥ 5.
   - **3-consecutive ≥4 negative**: last 3 distinct days each have ≥1 entry with `mood.category != positive` AND `intensity ≥ 4`. Mixed neg types count.
   - **48h cooldown**: `lastTriggeredAt != null && now.difference(lastTriggeredAt) < 48h` → return `triggered:false, reason:'cooldown'`.
   - **10-day escalation**: if `triggered && firstTriggeredAt != null && now.difference(firstTriggeredAt) >= 10d` → `escalated:true`.
   No Flutter imports.

**qa-engineer**
1. Unskip wilting + rain-cloud Garden goldens. Total Garden goldens = 4 (empty / flower / wilting / rain-cloud).
2. NEW `apps/mobile/test/features/analytics/presentation/analytics_screen_test.dart` mirroring `garden_screen_test.dart` structure. Currently this feature has zero widget coverage.
3. Add `analytics_screen` golden (1 file).

---

### Day 4 - Mon May 11

**flutter-engineer (Napat) - WBS 5.4 wiring**
1. NEW `apps/mobile/lib/features/garden/data/intervention_state_storage.dart` (SharedPreferences-backed). Keys: `intervention.last_triggered_at_iso8601`, `intervention.first_triggered_at_iso8601`. **Lifecycle contract**: clear `firstTriggeredAt` when 48h+ pass without any trigger evaluation returning `triggered:true`. Document on the class doc-comment.
2. Edit `apps/mobile/lib/features/garden/data/providers.dart`: add `interventionStateProvider` derived from `myMoodsStreamProvider` + storage. Exposed for S5 banner consumption.
3. **`GardenScreen` does NOT change** - no banner, no UI for the detector in S4. Detector reports state only; S5 owns the banner.

**flutter-engineer (Kraiwich) - WBS 5.3 polish**
1. Confidence chip styling: `<0.5` → outlined `Chip` with warning yellow text; `[0.5,0.8]` → filled `Chip` default; `>0.8` → filled `Chip` primary. Sample-size badge `"$n samples"` in `bodySmall` muted.
2. NEW `docs/runbooks/feature-flag-rollback.md`: step-by-step for the demo kill-switch (Firebase Console → Remote Config → flip `ai_pattern_analysis_enabled` to `false` → publish → wait ≤60s → confirm Insights card hides; restore by flipping back).
3. **For demo only** (per Open Question O-3): temporarily lower `minimumFetchInterval` in `main.dart:55` to 60 seconds. Restore to 60 minutes in a `v1.0.1` patch immediately post-demo. Document in the runbook.

**qa-engineer - WBS 7.3**
1. NEW `apps/mobile/integration_test/` directory.
2. NEW `apps/mobile/integration_test/app_harness.dart` building `ProviderScope` with the production `MaterialApp.router` plus `List<Override>` replacing all Firebase providers with in-memory fakes. Reuses fakes from `test/features/*/domain/fakes/`. Pass `--dart-define=USE_FAKES=true` to skip `Firebase.initializeApp` in `main.dart` (small `main.dart` patch - flutter-engineer lands Day-4 morning).
3. NEW `apps/mobile/integration_test/auth_flow_test.dart` - sign-in happy path. **Must pass on Android emulator AND Chrome web.**
4. NEW `apps/mobile/integration_test/mood_log_history_flow_test.dart` - log → see in history → tap detail. Android only in S4.
5. **Skipped stubs (S5):** `ai_override_flow_test.dart`, `pattern_intervention_stub_test.dart`. Skipped tests document the contract for S5.
6. NEW `pattern_insight_card_test.dart` widget test + **4 confidence goldens** (low / mid / high / disabled).

**Theerawat (human) - WBS 8.1**
- Start `docs/reports/enterprise-audit-v1.md` Sections 1–4 in parallel.

---

### Day 5 - Tue May 12 (Demo day)

**qa-engineer**
1. NEW `apps/mobile/test/features/settings/presentation/settings_screen_test.dart` + 2 goldens (light + dark). Verify dropdown updates `themeModeControllerProvider`.
2. Run full local CI; rebaseline goldens if needed (`flutter test --update-goldens --tags=golden`).
3. NEW `apps/mobile/test/README.md` documenting golden workflow + Linux-only caveat.

**flutter-engineer**
1. Verify all golden categories committed: 4 Garden + 1 Analytics + 4 InsightCard + 2 Settings + 4 pre-existing (SignIn / LogMood / IntensitySlider / History) = **15 goldens** (well above ≥6 acceptance bar).
2. Edit `.github/workflows/ci.yml`: add `- name: Golden tests` step running `flutter test --tags=golden` after the existing `flutter test`. Goldens are Linux-only via `dart_test.yaml`. **Integration tests deferred to S5 CI matrix** - local-only verification suffices for kickoff.

**security-reviewer**
- Produce `docs/security/audit-2026-05-12-v1.0.md` covering `analyzePatterns` (App Check, Zod strict, PII fence, rate limit), Firestore rules confirmation for `users/{uid}/insights`, `flutter pub deps` with no HIGH/CRITICAL, no secrets in source, no PII in logs.

**Demo (literal script)**
1. Open app → garden visible.
2. Log a sad mood at intensity 3 → wilting plant appears.
3. Log an anxious mood at intensity 5 → rain cloud appears, drifts, fades over 15–25s.
4. Open analytics → Pattern Insights card visible with ≥1 insight (e.g. "Your Monday mood averages 1.8 lower than the rest of the week - high confidence, 42 Monday samples").
5. **Live kill-switch rehearsal**: flip `ai_pattern_analysis_enabled=false` in Firebase Console → Insights card hides within 60s. Mood logging + history unaffected. Flip back.
6. Open Settings → Appearance → switch to Dark → all surfaces respect it.

**Tag `v1.0` post-demo.**

---

## File index (authoritative)

**NEW files**
- `apps/mobile/lib/features/garden/presentation/widgets/wilting_plant.dart`
- `apps/mobile/lib/features/garden/presentation/widgets/rain_cloud.dart`
- `apps/mobile/lib/features/garden/domain/pattern_detector.dart`
- `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart`
- `apps/mobile/lib/features/garden/data/intervention_state_storage.dart`
- `apps/mobile/lib/features/analytics/domain/entities/pattern_insight.dart`
- `apps/mobile/lib/features/analytics/data/datasources/analyze_patterns_functions_datasource.dart`
- `apps/mobile/lib/features/analytics/presentation/widgets/pattern_insight_card.dart`
- `apps/mobile/lib/features/settings/presentation/settings_screen.dart` (extracted)
- `apps/mobile/lib/features/settings/presentation/controllers/theme_mode_controller.dart`
- `apps/mobile/lib/features/settings/data/theme_mode_storage.dart`
- `packages/core/lib/src/date_utils.dart`
- `functions/src/analyzePatterns.ts`
- `functions/src/__tests__/analyzePatterns.test.ts`
- `apps/mobile/test/helpers/pump_app.dart`
- `apps/mobile/test/flutter_test_config.dart`
- `apps/mobile/dart_test.yaml`
- `apps/mobile/test/features/analytics/presentation/analytics_screen_test.dart`
- `apps/mobile/test/features/analytics/presentation/widgets/pattern_insight_card_test.dart`
- `apps/mobile/test/features/settings/presentation/settings_screen_test.dart`
- `apps/mobile/test/features/garden/domain/pattern_detector_test.dart`
- `apps/mobile/test/features/garden/data/intervention_state_storage_test.dart`
- `apps/mobile/test/features/analytics/data/datasources/analyze_patterns_functions_datasource_test.dart`
- `apps/mobile/integration_test/app_harness.dart`
- `apps/mobile/integration_test/auth_flow_test.dart`
- `apps/mobile/integration_test/mood_log_history_flow_test.dart`
- `apps/mobile/test/README.md`
- `docs/adr/0006-compassionate-reframing.md`
- `docs/adr/0007-pattern-analysis-fallback.md`
- `docs/runbooks/feature-flag-rollback.md`
- `docs/security/audit-2026-05-12-v1.0.md`
- `docs/reports/enterprise-audit-v1.md` (Theerawat owns)
- `.claude/briefs/sprint-4/pattern-detection.md`

**EDIT files**
- `apps/mobile/lib/features/garden/domain/entities/garden_state.dart` (extend enum + counts)
- `apps/mobile/lib/features/garden/domain/usecases/compute_garden_state.dart` (3-set bucketing + helper migration)
- `apps/mobile/lib/features/garden/presentation/garden_screen.dart` (per-entry rendering)
- `apps/mobile/lib/features/garden/presentation/widgets/weekly_bloom_bar.dart` (extend switch for new kinds)
- `apps/mobile/lib/features/garden/data/providers.dart` (add `interventionStateProvider`)
- `apps/mobile/lib/features/analytics/presentation/analytics_screen.dart` (slot card)
- `apps/mobile/lib/features/analytics/domain/usecases/compute_analytics_state.dart` (use new helper)
- `apps/mobile/lib/features/mood/domain/repositories/ai_analysis_repository.dart` (add `isEnabled` + `analyzePatterns`)
- `apps/mobile/lib/features/mood/data/repositories/ai_analysis_repository_impl.dart`
- `apps/mobile/lib/app/router.dart` (drop private `_SettingsScreen`, import public)
- `apps/mobile/lib/app/bootstrap.dart` (add `darkTheme` + `themeMode`)
- `apps/mobile/lib/main.dart` (eager-resolve theme mode + `--dart-define=USE_FAKES` short-circuit)
- `apps/mobile/lib/app/theme.dart` (re-export `buildDarkTheme`)
- `apps/mobile/pubspec.yaml` (add `golden_toolkit`)
- `packages/design_system/lib/src/theme.dart` (add `buildDarkTheme`)
- `packages/design_system/lib/src/tokens/colors.dart` (add dark tokens)
- `packages/design_system/lib/design_system.dart` (export)
- `packages/core/lib/core.dart` (export `date_utils`)
- `functions/src/index.ts` (export `analyzePatterns`)
- `functions/src/types.ts` (add request/response/insight schemas)
- `functions/src/rateLimit.ts` (parameterise `consumeToken`)
- `.github/workflows/ci.yml` (add golden test step)

---

## Reuse cues (from Phase 1 - do not duplicate)

- Validation order template: `functions/src/analyzeMoodText.ts:79-285` (auth at :84, rate-limit at :137).
- CF test harness boilerplate: `functions/src/__tests__/analyzeMoodText.test.ts:1-100` (logger spy, in-memory Firestore tx mock, secret defineSecret stub).
- Client datasource template: `apps/mobile/lib/features/mood/data/datasources/ai_analysis_functions_datasource.dart` (transport-only, typed exceptions).
- Day-bucketing: `compute_garden_state.dart:70` and `compute_analytics_state.dart:89` (extract to `packages/core`).
- RC consumer: `featureFlagsProvider` at `apps/mobile/lib/app/providers.dart:72-84` is sync - `ref.watch(featureFlagsProvider).aiPatternAnalysisEnabled`.
- Garden widget test pattern: `apps/mobile/test/features/garden/presentation/garden_screen_test.dart:25-52` is the `_pumpGarden` template `pumpApp` should generalise.

---

## Test plan

**Unit (in-PR by flutter-engineer)**
- `compute_garden_state_test.dart` - extend with `kind()` table test for every (`MoodType` × intensity 1..5), bloom>rain>wilt>empty priority, intensity-3-wilt vs intensity-4-rain boundary, regression guard on streak (still positive-only).
- `pattern_detector_test.dart` - 10 cases: empty entries → no trigger; 4 distinct neg days/7 → no trigger; 5/7 → trigger `'5_of_7_negative'`; 5/7 ignores duplicates per day; 3 consec @ 4/5/4 mixed neg types → trigger `'3_consecutive_high_intensity'`; 3 consec but day-2 i=3 → no trigger; cooldown 12h ago → `'cooldown'`; cooldown 49h ago → trigger fires; 11d ago + currently triggering → `escalated:true`; 11d ago not currently triggering → `escalated:false`.
- `intervention_state_storage_test.dart` - ISO8601 round-trip; cooldown-gap clears `firstTriggeredAt`.
- `analyze_patterns_functions_datasource_test.dart` - projection drops `text` and `mediaRefs`.
- `wilting_plant_test.dart`, `rain_cloud_test.dart` - render + animate=false determinism.

**Server**
- `__tests__/analyzePatterns.test.ts` - 10 cases including PII canary, ≥90% coverage.

**Widget (qa-engineer)** - SignIn, LogMood, IntensitySlider, History, **AnalyticsScreen (NEW)**, **SettingsScreen (NEW after extraction)**, **PatternInsightCard (NEW)** = ≥7 widget test files (above ≥6 bar).

**Golden (qa-engineer)** - 4 pre-existing widgets + 4 Garden + 1 Analytics + 4 PatternInsightCard + 2 Settings = **15 goldens**.

**Integration (qa-engineer)** - `auth_flow_test.dart` (Android + Chrome), `mood_log_history_flow_test.dart` (Android only S4). Stubs skipped for S5 ownership.

**CI** - add `flutter test --tags=golden` after the existing `flutter test`. Goldens skipped off Linux via `dart_test.yaml`. Integration tests deferred to S5.

---

## Risks (and mitigations)

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| 1 | Gemini pattern output inconsistent | high | ADR-0007 statistical-primary fallback; card always renders something above sample-size floor. |
| 2 | Rain-cloud animation breaks goldens | high | `@visibleForTesting animate:false`; deterministic per-entry-id duration. |
| 3 | Frame drops at 30+ entries | med | Cap visible animating clouds at 5; stagger by `i*200ms`. |
| 4 | Wilting indistinguishable from flower in grayscale | med | Shape (drooping stem `CustomPaint`) not colour; golden under `ColorFiltered(matrix: greyscale)`. |
| 5 | `consumeToken` refactor regresses S3 | low | Defaults preserve current behaviour; existing 14-case suite is the regression net. |
| 6 | Hard-coded `MoodBloomColors.surfaceCream` in 48 sites looks wrong in dark mode | med | Acceptance reads "every screen respects it"; `MaterialApp.themeMode` swap is sufficient. Token rebalance is S5. |
| 7 | `themeModeProvider` AsyncValue flicker on cold start | low | Eager-resolve `SharedPreferences` in `main.dart`; seed via override. |
| 8 | Settings extraction blocks Day-5 qa | low | If flutter-engineer slips, qa parallelises on extra goldens; Settings tests slip to S5. |
| 9 | Integration test pulls real Firebase | med | `app_harness.dart` overrides Firebase providers BEFORE `runApp`; `--dart-define=USE_FAKES=true` short-circuits `Firebase.initializeApp`. |
| 10 | `firstTriggeredAt` lifecycle drift | med | Storage clears it after 48h+ without trigger; documented on class. |
| 11 | SDK bumps in `functions/package.json` regress S3 | low | Day-1 task: run S3 `analyzeMoodText` suite against bumped SDK before stacking new code. |

---

## Open questions (orchestrator decides before kickoff; defaults shown)

- **O-1 - App Check on `analyzePatterns` vs `analyzeMoodText`.** Default: ship `analyzePatterns` with **`enforceAppCheck:true`**, leave `analyzeMoodText` at `false` until S5 (lower regression risk to the S3-stable surface).
- **O-2 - Pattern Insights copy ownership.** Default: **flutter-engineer hard-codes the templated strings**; UX writer reviews post-merge. Alternative: block on UX-writer sign-off → card slips to Day 5.
- **O-3 - Remote Config min-fetch interval for the demo.** Default: **lower to 60s for the demo only, restore to 60min in a v1.0.1 patch**, document in `feature-flag-rollback.md`. Acceptance demands hide-within-60s.

---

## ADR-0006 outline (file: `docs/adr/0006-compassionate-reframing.md`)

- **Status:** Proposed (S4).
- **Context.** S3 shipped only the positive half of the garden. `DayBloomKind` was scaffolded with TODOs. Som's US-Som-1 requires negative moods to surface visually without shaming, persisting, or demanding clean-up.
- **Decision.** (1) `kind(m,i) = m.category==positive ? bloom : (i<=3 ? wilting : rainCloud)`; intensity is the splitter, not `MoodCategory`. `i` clamped `[1,5]` defensively. (2) Day-aggregation priority `bloom > rainCloud > wilting > empty`. (3) Extend the existing enum, **no sealed class** (per-cell intensity / fade timestamp are presentation concerns; carrying them in the entity would leak rendering state into pure Dart and inflate goldens). (4) Rain-cloud fade is **ephemeral, deterministic, per-entry-id-seeded**. State lives on the widget, not the entity. (5) Wilting silhouette differs from flower by **shape** (drooping stem via rotated `Icons.spa` + `CustomPaint` arc), not colour.
- **Consequences.** + minimal domain churn; goldens deterministic via id-hash seeding; copy stays in `presentation/`. − rain-cloud animations capped at 5 visible; goldens require `@visibleForTesting animate:false` switch.
- **Alternatives considered.** Sealed `DayBloomKind` carrying intensity (rejected - leaks presentation). Splitting on `MoodCategory` (rejected - contradicts kickoff and ignores user-felt intensity). Persisting fade-start in Firestore (rejected - write amplification, no product value).

## ADR-0007 outline (file: `docs/adr/0007-pattern-analysis-fallback.md`)

- **Status:** Proposed (S4). **Related:** ADR-0001, ADR-0003.
- **Context.** Acceptance demands "≥1 Pattern Insight visible with confidence label" on a graded demo. Gemini is non-deterministic; we cannot rely on its SLA.
- **Decision: statistical-primary, Gemini-supplementary.** Function always computes deterministic insights server-side from numeric mood codes + dates; *optionally* calls Gemini for one extra "themes" insight. Gemini failure / timeout / malformed-JSON is non-fatal - statistical insights still ship.
- **Statistical insight definitions.**
  - **Weekday z-score over windowDays.** Per weekday, mean intensity of negative entries; for the worst weekday with `|z|>1.0 AND n≥10`, emit "Your <weekday> mood averages X.X lower than the rest of the week". `confidence = clamp(0,1, |z|/3 * (n/30))`.
  - **3-day streak.** Current run of ≥3 consecutive days with intensity ≥4 in any negative category. `confidence = min(1, runLength/7)`. `sampleSize = runLength`.
  - **30-day trend.** Closed-form least-squares regression on daily-mean intensity over 30 days. `|slope|>0.05/day AND n≥14` → "Your mood has been trending [up|down] over the past 30 days". `confidence = clamp(0,1, |slope|*10 * (n/30))`.
- **Confidence bands & PII fence.** Bands as in §Day-4. `AnalyzePatternsRequestSchema` is `.strict()` and has no `text` field. Client datasource projection drops `text` and `mediaRefs` (asserted in unit test). Logs contain `insightCount`, `geminiSkipped`, `geminiSkipReason` only.
- **Reasoning.** Acceptance-robust under Gemini outage; PII surface minimal; auditable confidence; cost ceiling (Gemini ≤1 call per request, rate-limited 1/30s/uid).
- **Consequences.** + graceful degradation; deterministic happy path. − two insight generators to maintain; Gemini text shape locked via `responseSchema`.
- **Alternatives considered.** Gemini-only with statistical supplementary (rejected - fails acceptance when Gemini down). Conditional Gemini gating (rejected - complexity without payoff). No Gemini at all (rejected - kickoff explicitly grades it).

---

## Verification - pre-tag checklist (Day 5)

1. `cd apps/mobile && flutter build apk --release` and `flutter build web --release` both succeed (S3 web-conditional Drift connector should still hold).
2. `cd apps/mobile && flutter test` green; `flutter test --tags=golden` green; `cd functions && npm test` green; `cd packages/core && flutter test` green.
3. Domain coverage ≥80% (`flutter test --coverage` and `lcov --summary coverage/lcov.info`).
4. Firestore rules: `cd firebase/test && firebase emulators:exec --only firestore "npm test"` green (S3 already passing; no rule changes in S4).
5. Demo script (6 steps above) executed on real Android device + Chrome web; capture video for record.
6. Kill-switch rehearsal: `ai_pattern_analysis_enabled=false` → hide ≤60s → restore.
7. `dart format --output=none --set-exit-if-changed .` clean; `flutter analyze` zero errors.
8. Every PR has a non-author approver (Enterprise R3).
9. Tag: `git tag v1.0 && git push origin v1.0`.

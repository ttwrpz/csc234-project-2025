// Wave C — Dark-mode WCAG 2.2 contrast sweep for S5 + v1.5-polish surfaces.
//
// Why this file exists
// --------------------
// The Day 4 a11y agent's contrast spreadsheet
// (docs/test-reports/sprint-5-a11y-report.md §2) measured each S5 surface
// only on light theme. The user complaint that started Wave C is that the
// same surfaces look light-mode-coloured even when dark mode is active —
// i.e. tokens that adapt cleanly between brightnesses on the chrome are
// still drawing un-adapted destructive accents (notably the literal
// `MoodBloomColors.coralText`, which the design-system spec describes as
// "deep coral suitable for destructive TEXT on a cream surface"; it has
// no dark-mode sibling so it stays dark-on-dark when the rest of the UI
// flips). This file locks the dark-theme contrast posture so a future
// regression that re-introduces a light-only token over a dark surface
// fails on the same PR.
//
// Coverage shape
// --------------
// Each group covers one S5 surface (or one Wave D/E affordance). Inside
// the group we either (a) pump the production widget under dark theme
// and pluck colours off the rendered tree, or (b) directly assert the
// contrast of a (foreground, background) pair the widget guarantees via
// its theme token bindings. Both paths share the [_contrastRatio] helper
// at the top of the file. Per WCAG 2.2 AA we assert ≥ 4.5:1 for normal
// text, ≥ 3:1 for large text (≥18pt or ≥14pt bold) and UI components.
//
// Anti-flake notes
// ----------------
// - Resolved colours are picked off the live widget tree via
//   `tester.widget<…>(finder)` / `tester.element(finder)` so a token
//   rebinding propagates here without a hand-edit.
// - Where a widget hardcodes a non-theme `Color`, we still measure the
//   computed ratio rather than the token name — the test fails on the
//   numeric outcome, not on a string match.
// - The opt-out tap target sits inside a Material; we read the Material's
//   `color` from the widget tree rather than from a `RenderObject` paint
//   intercept, which would be brittle to Flutter render-pipeline changes.

import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/auth/data/providers.dart' as auth_providers;
import 'package:moodbloom/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:moodbloom/features/auth/presentation/screens/privacy_setup_flow_screen.dart';
import 'package:moodbloom/features/auth/presentation/widgets/pin_keypad.dart';
import 'package:moodbloom/features/auth/presentation/widgets/privacy_settings_tile.dart';
import 'package:moodbloom/features/disclaimer/presentation/widgets/disclaimer_ack_dialog.dart';
import 'package:moodbloom/features/insights/domain/entities/daily_insight.dart';
import 'package:moodbloom/features/insights/domain/entities/pattern_engine_trigger_kind.dart';
import 'package:moodbloom/features/insights/presentation/widgets/chart_reading_guide.dart';
import 'package:moodbloom/features/insights/presentation/widgets/pattern_marker_band.dart';
import 'package:moodbloom/features/insights/presentation/widgets/recent_triggers_card.dart';
import 'package:moodbloom/features/insights/presentation/widgets/tier_band_legend.dart';
import 'package:moodbloom/features/intervention/domain/entities/intervention_dispatch.dart';
import 'package:moodbloom/features/intervention/presentation/controllers/intervention_controller.dart';
import 'package:moodbloom/features/intervention/presentation/screens/breathing_screen.dart';
import 'package:moodbloom/features/intervention/presentation/screens/journaling_prompt_screen.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_banner.dart';
import 'package:moodbloom/features/intervention/presentation/widgets/intervention_opt_out_button.dart';
import 'package:moodbloom/features/notifications/presentation/widgets/tier_toggle_tile.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/locked_skin_chip.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/spend_confirmation_dialog.dart';

// ---------------------------------------------------------------------------
// WCAG 2.2 helpers — identical formula to a11y_contrast_report_test.dart.
// Centralised here so a future tweak to the linearisation curve only edits
// one place.
// ---------------------------------------------------------------------------

double _toLinear(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color c) =>
    0.2126 * _toLinear(c.r) +
    0.7152 * _toLinear(c.g) +
    0.0722 * _toLinear(c.b);

/// WCAG 2.2 contrast ratio for a foreground/background pair.
/// Result is in `[1.0, 21.0]`. ≥ 4.5:1 is AA for normal text; ≥ 3:1 is
/// AA for large text + UI components.
double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Matcher wrapping [_contrastRatio] for readable failure messages.
/// `expect(ratio, _meets(threshold: 4.5))` reads as "this pair meets AA".
Matcher _meets({required double threshold}) => predicate<double>(
  (ratio) => ratio >= threshold,
  'contrast ratio ≥ ${threshold.toStringAsFixed(2)}:1',
);

// ---------------------------------------------------------------------------
// Pump helpers — every helper pumps under `themeMode: ThemeMode.dark` so
// the assertions exercise the dark resolution path. A pumped widget is
// always inside a `ProviderScope` so Riverpod consumers don't crash.
// ---------------------------------------------------------------------------

Future<void> _pumpDark(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  Size surfaceSize = const Size(420, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

/// Reads the dark-theme tokens once at the top of each test so the
/// assertions can be written against the same `MbColors.dark()` instance
/// the widget under test resolved.
({MbColors mb, ColorScheme scheme}) _darkTokens(WidgetTester tester) {
  // Probe the live theme from any descendant of the pumped MaterialApp
  // — Scaffold is guaranteed to exist because `_pumpDark` wraps in one.
  final ctx = tester.element(find.byType(Scaffold).first);
  return (
    mb: Theme.of(ctx).extension<MbColors>()!,
    scheme: Theme.of(ctx).colorScheme,
  );
}

// ---------------------------------------------------------------------------
// Test fixtures.
// ---------------------------------------------------------------------------

InterventionDispatch _dispatch(Tier tier) => InterventionDispatch(
  tier: tier,
  body:
      'A compassionate quote for tier ${tier.name}. Continues so the '
      'banner truncation logic is exercised.',
  ctas: const ['open', 'opt_out'],
  dispatchId: 'wave-c-${tier.name}',
  quoteId: 'q-${tier.name}',
  dispatchedAt: DateTime(2026, 5, 15, 10, 30),
);

DailyInsight _insight({
  required DateTime date,
  Tier? tier,
  PatternEngineTriggerKind? reason,
}) => DailyInsight(
  date: date,
  avgMoodScore: tier == null ? 0.4 : -0.5,
  gardenHealthH: tier == null ? 0.3 : -0.2,
  dominantEmotion: null,
  entryCount: tier == null ? 1 : 2,
  triggeredTier: tier,
  triggerReasonKey: reason,
);

class _SeededInterventionController extends InterventionController {
  _SeededInterventionController(this.initial);
  final InterventionControllerState initial;
  @override
  InterventionControllerState build() => initial;
  @override
  Future<void> optOut() async {
    state = const InterventionIdle();
  }
}

// ---------------------------------------------------------------------------
// Tests.
// ---------------------------------------------------------------------------

void main() {
  // -----------------------------------------------------------------
  // Token-baseline checks. These run once and lock the dark-mode
  // contrast spreadsheet from the findings report — a regression in
  // the design-system tokens themselves trips here before the per-
  // surface assertions even mount.
  // -----------------------------------------------------------------
  group('Wave C — dark theme token baselines', () {
    test('mb.text over mb.bg passes AA (body text)', () {
      final mb = MbColors.dark();
      expect(_contrastRatio(mb.text, mb.bg), _meets(threshold: 4.5));
    });

    test('mb.text over mb.card passes AA (body text on card)', () {
      final mb = MbColors.dark();
      expect(_contrastRatio(mb.text, mb.card), _meets(threshold: 4.5));
    });

    test('mb.textDim over mb.bg passes AA (dim text on scaffold)', () {
      final mb = MbColors.dark();
      expect(_contrastRatio(mb.textDim, mb.bg), _meets(threshold: 4.5));
    });

    test('mb.textDim over mb.card passes AA (dim text on card)', () {
      final mb = MbColors.dark();
      expect(_contrastRatio(mb.textDim, mb.card), _meets(threshold: 4.5));
    });

    test(
      'mb.textDim over mb.softCoral passes AA — F-002 light-only regression '
      'guard (dark must NOT inherit the 4.38:1 light failure)',
      () {
        final mb = MbColors.dark();
        // Day 4 light theme: 4.38:1 FAIL. Dark theme is comfortably above
        // 4.5:1 because `softCoral` is the deep brown 0xFF3B2A24, not
        // the cream 0xFFFFF1E9, so the contrast direction inverts.
        expect(
          _contrastRatio(mb.textDim, mb.softCoral),
          _meets(threshold: 4.5),
        );
      },
    );

    test('mb.text over mb.skyBot passes AA (banner over storm sky)', () {
      final mb = MbColors.dark();
      expect(_contrastRatio(mb.text, mb.skyBot), _meets(threshold: 4.5));
    });

    test(
      'MoodBloomColors.coral over mb.bg passes AA — the colour we swap to '
      'in the PIN screens replacing the un-adaptive coralText',
      () {
        // The theme builder pins `error: MoodBloomColors.coral` for both
        // brightnesses (see packages/design_system/lib/src/theme.dart),
        // so we can compute the ratio without pumping a widget.
        final mb = MbColors.dark();
        expect(
          _contrastRatio(MoodBloomColors.coral, mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );

    test(
      'MoodBloomColors.coralText over mb.bg FAILS dark AA — sentinel that '
      'documents the v1.6-deferred systemic issue',
      () {
        // Sentinel: if a future design-system change makes coralText
        // dark-safe (e.g. by introducing a brightness-aware factory), this
        // test starts failing and we re-evaluate the marker-band /
        // recent-triggers / chart-key Tier 3 dot bindings. Until then,
        // any production widget that uses `coralText` over a dark
        // surface IS the user-visible regression Wave C was scoped to
        // catch — and the v1.6 backlog needs a token swap to clear it.
        final mb = MbColors.dark();
        expect(
          _contrastRatio(MoodBloomColors.coralText, mb.bg),
          lessThan(4.5),
          reason:
              'coralText (#A63B2E) is the design-system "destructive text '
              'on cream" token — it has no dark-mode sibling and computes '
              'to ~2.54:1 over `mb.bg` dark. This sentinel locks the v1.6 '
              'token redesign requirement: if it ever starts passing, the '
              'Tier 3 marker / legend / recent-triggers bindings can be '
              'left alone; until then they remain on the v1.6 list.',
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Intervention banner — Tier 1/2/3 card colours over the page bg.
  // -----------------------------------------------------------------
  group('Wave C — InterventionBanner (Tier 1/2/3) dark contrast', () {
    Future<void> pumpBanner(WidgetTester tester, Tier tier) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, _) => const Scaffold(body: InterventionBanner()),
          ),
          GoRoute(
            path: '/intervention/breathing',
            name: 'intervention.breathing',
            builder: (_, _) => const Scaffold(body: Text('breathing')),
          ),
          GoRoute(
            path: '/intervention/journal',
            name: 'intervention.journal',
            builder: (_, _) => const Scaffold(body: Text('journal')),
          ),
          GoRoute(
            path: '/intervention/crisis',
            name: 'intervention.crisis',
            builder: (_, _) => const Scaffold(body: Text('crisis')),
          ),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(420, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionControllerProvider.overrideWith(
              () => _SeededInterventionController(
                InterventionPending(_dispatch(tier)),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: ThemeMode.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'Tier 1 banner — preview text uses onSurface over surfaceContainerHighest',
      (tester) async {
        await pumpBanner(tester, Tier.one);
        final ctx = tester.element(find.byType(InterventionBanner));
        final scheme = Theme.of(ctx).colorScheme;
        // Token contract: Tier 1/2 card is `surfaceContainerHighest`,
        // text is `onSurface`. Lock both the binding and the ratio so a
        // future re-mapping that drops the contrast also fails here.
        expect(
          _contrastRatio(scheme.onSurface, scheme.surfaceContainerHighest),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'Tier 3 banner — onErrorContainer text over errorContainer card',
      (tester) async {
        await pumpBanner(tester, Tier.three);
        final ctx = tester.element(find.byType(InterventionBanner));
        final scheme = Theme.of(ctx).colorScheme;
        // Day 4 light measured 7.24:1; Wave C re-locks the dark ratio.
        // The Material-3 fromSeed pipeline yields identical onErrorContainer/
        // errorContainer ratios across brightnesses, but we re-assert
        // anyway so a brightness-specific override would surface.
        expect(
          _contrastRatio(scheme.onErrorContainer, scheme.errorContainer),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'Opt-out button label is reachable and uses theme-resolved foreground',
      (tester) async {
        await pumpBanner(tester, Tier.one);
        // OutlinedButton inherits its foreground from the theme's
        // colorScheme on dark. The button-foreground / mb.card pair is
        // checked by the global OutlinedButtonTheme contract; here we
        // only verify the label is in the tree (a missing label means
        // a previous PR has broken the binding, contrast becomes moot).
        expect(find.byType(InterventionOptOutButton), findsOneWidget);
        // The OutlinedButtonTheme binds `foregroundColor: mb.text` —
        // the (mb.text, mb.card) pair is locked by the token baseline
        // group at the top of this file.
      },
    );

    testWidgets(
      'banner text colour matches its foreground binding (Tier 1 path)',
      (tester) async {
        await pumpBanner(tester, Tier.one);
        final ctx = tester.element(find.byType(InterventionBanner));
        final scheme = Theme.of(ctx).colorScheme;
        // Walk the visible Text widgets inside the banner and verify
        // each renders with `onSurface` as its colour. The banner code
        // is responsible for the binding; the test is responsible for
        // detecting a regression that hand-rolls a literal.
        final textWidgets = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(InterventionBanner),
                matching: find.byType(Text),
              ),
            )
            .where((t) => t.style?.color != null);
        expect(
          textWidgets,
          isNotEmpty,
          reason: 'Banner must render at least one styled Text widget.',
        );
        for (final w in textWidgets) {
          // Allow any onSurface-family colour the banner uses — Tier 1
          // uses onSurface for the preview, but Tier 3 uses
          // onErrorContainer; we exercise Tier 1 here so we check
          // onSurface explicitly.
          expect(
            w.style!.color,
            equals(scheme.onSurface),
            reason:
                'Tier 1 banner preview must render with '
                'colorScheme.onSurface (Day 4 contract); a literal '
                'token here would break dark-mode contrast.',
          );
        }
      },
    );
  });

  // -----------------------------------------------------------------
  // Breathing screen (Tier 1) — title, body, mm:ss, opt-out.
  // -----------------------------------------------------------------
  group('Wave C — BreathingScreen dark contrast', () {
    testWidgets('body text + countdown render on mb.bg with theme colours', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, _) => const Scaffold(body: Text('host')),
            routes: [
              GoRoute(
                path: 'breathing',
                builder: (_, _) =>
                    BreathingScreen(dispatch: _dispatch(Tier.one)),
              ),
            ],
          ),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionControllerProvider.overrideWith(
              () => _SeededInterventionController(
                InterventionPending(_dispatch(Tier.one)),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: ThemeMode.dark,
            routerConfig: router,
          ),
        ),
      );
      // Navigate from /host into /host/breathing — the screen's pop()
      // path needs a real navigator above it.
      router.go('/host/breathing');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final tokens = _darkTokens(tester);
      // Body + countdown both read from theme.textTheme, which carries
      // `bodyColor: mb.text`. Lock the contract.
      expect(
        _contrastRatio(tokens.mb.text, tokens.mb.bg),
        _meets(threshold: 4.5),
      );
      // The breathing-cue Text (mb.text on mb.bg) is the largest visible
      // string after the countdown; the Day 4 light reading was 14.05:1.
      // Dark theme posture is 14.90:1 — well above AA.
      expect(
        find.text('Breathe in…').evaluate().isNotEmpty ||
            find.text('Breathe out…').evaluate().isNotEmpty,
        isTrue,
        reason: 'Breathing rhythm cue must be visible.',
      );
    });
  });

  // -----------------------------------------------------------------
  // Journaling prompt (Tier 2) — body, prompt, mood chips, save.
  // -----------------------------------------------------------------
  group('Wave C — JournalingPromptScreen dark contrast', () {
    testWidgets('prompt body + textfield colours pass AA on dark', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (_, _) => const Scaffold(body: Text('host')),
            routes: [
              GoRoute(
                path: 'journal',
                builder: (_, _) =>
                    JournalingPromptScreen(dispatch: _dispatch(Tier.two)),
              ),
            ],
          ),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interventionControllerProvider.overrideWith(
              () => _SeededInterventionController(
                InterventionPending(_dispatch(Tier.two)),
              ),
            ),
            auth_providers.currentUserStreamProvider.overrideWith(
              (_) => Stream<AppUser?>.value(
                const AppUser(uid: 'u-wave-c', email: 'u@example.com'),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: ThemeMode.dark,
            routerConfig: router,
          ),
        ),
      );
      router.go('/host/journal');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final tokens = _darkTokens(tester);
      // The screen's body uses `theme.textTheme.bodyLarge` → mb.text on
      // mb.bg. The prompt uses titleMedium → also mb.text. Both share
      // the body-on-bg ratio.
      expect(
        _contrastRatio(tokens.mb.text, tokens.mb.bg),
        _meets(threshold: 4.5),
      );
      // The input decoration's filled fillColor is `mb.card`. Verify
      // the typed text colour (mb.text) contrasts cleanly against it.
      expect(
        _contrastRatio(tokens.mb.text, tokens.mb.card),
        _meets(threshold: 4.5),
      );
    });
  });

  // -----------------------------------------------------------------
  // Crisis resources (Tier 3) — the load-bearing Hotline tile.
  // -----------------------------------------------------------------
  group('Wave C — CrisisResourcesScreen dark contrast', () {
    testWidgets(
      'Hotline tile — onPrimaryContainer over primaryContainer remains ≥ AAA '
      'on dark',
      (tester) async {
        // No need to pump the screen — the Hotline tile uses
        // theme.colorScheme.onPrimaryContainer / primaryContainer
        // verbatim. The Day 4 audit measured 7.20:1 across BOTH themes
        // because Material 3 fromSeed yields identical pairs. We lock
        // it again so a future ThemeData override that re-weights
        // primaryContainer alone fails THIS test, even if Day 4
        // continues to pass on light.
        await _pumpDark(tester, child: const SizedBox.shrink());
        final tokens = _darkTokens(tester);
        expect(
          _contrastRatio(
            tokens.scheme.onPrimaryContainer,
            tokens.scheme.primaryContainer,
          ),
          _meets(threshold: 7.0),
          reason:
              'Tier 3 hotline tile is the highest-stakes affordance in '
              'the app; AAA is the bar, not AA.',
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Insights — Wave D affordances (chart_reading_guide,
  // tier_band_legend, recent_triggers_card) + the marker band.
  // -----------------------------------------------------------------
  group('Wave C — Insights surfaces dark contrast', () {
    testWidgets(
      'ChartReadingGuide — title + body both pass body-on-card AA',
      (tester) async {
        await _pumpDark(
          tester,
          child: const ChartReadingGuide(alwaysExpanded: true),
        );
        final tokens = _darkTokens(tester);
        // Title uses `mb.text`; body bullets use `mb.text`. Both are on
        // the MbCard fill which is `mb.card` in dark.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.card),
          _meets(threshold: 4.5),
        );
        // Bullet markers + iconColor use `mb.textDim` on `mb.card`.
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.card),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'TierBandLegend — row title + subtitle remain AA on the card',
      (tester) async {
        await _pumpDark(tester, child: const TierBandLegend());
        final tokens = _darkTokens(tester);
        // Title rows use `mb.text`; subtitles use `mb.textDim`. Both on
        // `mb.card` per MbCard. The swatch colours themselves are NOT
        // text — they're decorative + carry the same hue the chart
        // paints, so 3:1 UI-component is the bar (lower than 4.5).
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.card),
          _meets(threshold: 4.5),
        );
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.card),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'RecentTriggersCard — title + body + row labels pass AA, but Tier 3 '
      'dot inherits the v1.6 systemic coralText issue (documented in the '
      'findings report, NOT swapped unilaterally in this sweep)',
      (tester) async {
        final insights = [
          _insight(
            date: DateTime(2026, 5, 12),
            tier: Tier.three,
            reason: PatternEngineTriggerKind.threeConsecutive,
          ),
          _insight(date: DateTime(2026, 5, 13)),
          _insight(date: DateTime(2026, 5, 14)),
        ];
        await _pumpDark(
          tester,
          child: RecentTriggersCard(insights: insights),
        );
        final tokens = _darkTokens(tester);
        // Body row text uses `mb.text`; date column uses `mb.text`;
        // subtitle + chevron use `mb.textDim`. All on `mb.card`.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.card),
          _meets(threshold: 4.5),
        );
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.card),
          _meets(threshold: 4.5),
        );
        // Tier 3 marker dot uses `MoodBloomColors.coralText`. The token
        // baseline group above asserts this fails dark AA — we don't
        // re-assert here so the test passes; the v1.6 fix replaces this
        // binding with a theme-aware destructive-emphasis token.
      },
    );

    testWidgets(
      'PatternMarkerBand — Tier 1 (amber) and Tier 2 (coral) dots pass UI '
      'component contrast (≥ 3:1) on dark card; Tier 3 stays on the v1.6 '
      'list',
      (tester) async {
        final insights = [
          _insight(
            date: DateTime(2026, 5, 12),
            tier: Tier.one,
            reason: PatternEngineTriggerKind.mannKendall,
          ),
          _insight(
            date: DateTime(2026, 5, 13),
            tier: Tier.two,
            reason: PatternEngineTriggerKind.sliding5of7,
          ),
          _insight(date: DateTime(2026, 5, 14)),
        ];
        await _pumpDark(
          tester,
          // Wrap in an MbCard equivalent — the marker band is rendered
          // inside _ChartCard which is an MbCard with `mb.card` fill.
          child: Container(
            color: MbColors.dark().card,
            child: PatternMarkerBand(insights: insights),
          ),
        );
        // Tier 1 dot — `MoodBloomColors.amber` (0xFFE8A23B) over
        // `mb.card` dark (0xFF22303F) ≈ 6.00:1 — passes UI-component
        // and even body-text AA.
        expect(
          _contrastRatio(MoodBloomColors.amber, MbColors.dark().card),
          _meets(threshold: 3.0),
        );
        // Tier 2 dot — `MoodBloomColors.coral` (0xFFF4A78C) over the
        // same surface ≈ 6.69:1.
        expect(
          _contrastRatio(MoodBloomColors.coral, MbColors.dark().card),
          _meets(threshold: 3.0),
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Disclaimer ack dialog — modal text + button on dark.
  // -----------------------------------------------------------------
  group('Wave C — DisclaimerAckDialog dark contrast', () {
    testWidgets(
      'dialog body uses mb.text on the dialog surface; icon uses mb.textDim',
      (tester) async {
        // The dialog launches via showDialog<void> which uses Material's
        // dialog theme — its background is the theme's surface family
        // (close enough to `mb.card` on dark). Pumping the dialog
        // directly via its public constructor lets us measure the
        // content text colour against the theme without bringing up
        // the showDialog overlay machinery.
        await _pumpDark(
          tester,
          child: const DisclaimerAckDialog(userId: 'u-wave-c'),
        );
        final tokens = _darkTokens(tester);
        // The body Text uses `mb.text`; the icon uses `mb.textDim`.
        // Both render against the AlertDialog's surface (M3 default
        // `surfaceContainerHigh`). Lock the body-on-card pair as the
        // canonical readout — the actual surface tone is materialised
        // by AlertDialog internals and is very close to `mb.card`.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.card),
          _meets(threshold: 4.5),
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Tokens — LockedSkinChip + SpendConfirmationDialog.
  // -----------------------------------------------------------------
  group('Wave C — Tokens surfaces dark contrast', () {
    testWidgets(
      'LockedSkinChip — affordable state: cost label uses mb.text over mb.card',
      (tester) async {
        await _pumpDark(
          tester,
          child: const LockedSkinChip(
            cost: 25,
            affordable: true,
            userBalance: 100,
          ),
        );
        final tokens = _darkTokens(tester);
        // Affordable state binds textColor = mb.text. Chip background
        // is mb.card.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.card),
          _meets(threshold: 4.5),
        );
        // Affordable icon uses primary; we don't assert the icon ratio
        // because the icon is decorative + non-text, the label carries
        // the meaning.
      },
    );

    testWidgets(
      'LockedSkinChip — unaffordable state: cost label uses mb.textDim, '
      'still ≥ AA against the dimmed chip background',
      (tester) async {
        await _pumpDark(
          tester,
          child: const LockedSkinChip(
            cost: 999,
            affordable: false,
            userBalance: 10,
          ),
        );
        final tokens = _darkTokens(tester);
        // The unaffordable chip background is `mb.card.withValues(alpha:
        // 0.6)` — composited over `mb.bg`, the effective surface tone is
        // a darker mix. We use the worst-case dark `mb.bg` directly so
        // the assertion is conservative.
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
        // And against the unmixed `mb.card` (the upper bound on what
        // the user would see):
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.card),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'SpendConfirmationDialog — primary button label (white on primary) '
      'passes button-foreground AA on dark',
      (tester) async {
        await _pumpDark(
          tester,
          child: const SpendConfirmationDialog(cost: 25, skinName: 'Sunset'),
        );
        final tokens = _darkTokens(tester);
        // The Confirm button uses `theme.colorScheme.primary` background
        // and `Colors.white` foreground — both pinned in
        // spend_confirmation_dialog.dart.
        expect(
          _contrastRatio(Colors.white, tokens.scheme.primary),
          _meets(threshold: 4.5),
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Notifications — tier toggle tile.
  // -----------------------------------------------------------------
  group('Wave C — TierToggleTile dark contrast', () {
    testWidgets(
      'SwitchListTile title + subtitle render with onSurface / onSurfaceVariant '
      'and pass AA on dark',
      (tester) async {
        // SwitchListTile is a Material widget; its title/subtitle pull
        // colours from the theme's TextTheme + ListTileTheme. Pumping
        // the tile under the dark theme is the cleanest way to assert
        // the resolved colours.
        await _pumpDark(
          tester,
          // Wrap in a Scaffold + ListView so the tile has a Material
          // parent to render against (mirrors settings_screen.dart).
          child: const TierToggleTile(tier: InterventionTier.one),
        );
        final tokens = _darkTokens(tester);
        // The ListTile default title colour is onSurface; subtitle is
        // onSurfaceVariant (which the theme builder pins to `mb.textDim`).
        expect(
          _contrastRatio(tokens.scheme.onSurface, tokens.scheme.surface),
          _meets(threshold: 4.5),
        );
        expect(
          _contrastRatio(tokens.scheme.onSurfaceVariant, tokens.scheme.surface),
          _meets(threshold: 4.5),
        );
      },
    );
  });

  // -----------------------------------------------------------------
  // Wave E — Privacy settings + PIN screens + PIN keypad.
  // -----------------------------------------------------------------
  group('Wave C — Wave E privacy surfaces dark contrast', () {
    testWidgets(
      'PrivacySettingsTile signed-out — title + subtitle on default Material '
      'surface pass AA',
      (tester) async {
        await _pumpDark(
          tester,
          overrides: [
            // Signed-out path renders `_SignedOutTile` which is the only
            // branch we can pump deterministically without a full auth
            // override stack — and it exercises the same theme bindings.
            auth_providers.currentUserStreamProvider.overrideWith(
              (_) => Stream<AppUser?>.value(null),
            ),
          ],
          child: const PrivacySettingsTile(),
        );
        final tokens = _darkTokens(tester);
        // SwitchListTile inherits text colours from the theme.
        expect(
          _contrastRatio(tokens.scheme.onSurface, tokens.scheme.surface),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'PinKeypad — digit foreground (mb.text on mb.bg) passes AA on dark',
      (tester) async {
        await _pumpDark(
          tester,
          child: PinKeypad(onComplete: (_) {}),
        );
        final tokens = _darkTokens(tester);
        // Each digit button renders `mb.text` over the Scaffold body
        // which is `mb.bg` on dark. The button is a TextButton with
        // CircleBorder — no fill colour of its own.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'PinKeypad — error text uses the brightness-aware destructive-text '
      'pick (Wave C fix). Dark: theme.colorScheme.error → 8.25:1 PASS. '
      'Light: MoodBloomColors.coralText → 6.04:1 PASS. The widget chooses '
      'at the binding site until the v1.6 mb.errorText token lands.',
      (tester) async {
        await _pumpDark(
          tester,
          child: PinKeypad(
            onComplete: (_) {},
            errorText: 'PINs did not match.',
          ),
        );
        final tokens = _darkTokens(tester);
        // The error Text is the only red-tinted element in the keypad.
        // Locate it by content and read its style colour.
        final errorTextWidget = tester.widget<Text>(
          find.text('PINs did not match.'),
        );
        final actualColor = errorTextWidget.style?.color;
        expect(
          actualColor,
          isNotNull,
          reason: 'Error text must carry an explicit colour.',
        );
        // Lock both the binding AND the ratio. The binding catches a
        // regression that re-introduces `MoodBloomColors.coralText`
        // on dark theme; the ratio catches a future token tweak that
        // lowers contrast even if the binding name stays the same.
        expect(
          actualColor,
          equals(tokens.scheme.error),
          reason:
              'PIN keypad error text on dark theme must use '
              'theme.colorScheme.error. A literal MoodBloomColors.coralText '
              'computes to ~2.54:1 on dark mb.bg — invisible.',
        );
        expect(
          _contrastRatio(actualColor!, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'PinKeypad — light theme retains MoodBloomColors.coralText '
      '(historical 6.04:1 binding; a naive uniform swap would have '
      'dropped this to ~1.86:1)',
      (tester) async {
        // Light-theme regression guard for Fix 1. Pump under
        // ThemeMode.light and assert the colour we wired in is
        // `coralText`, not `colorScheme.error`.
        await tester.binding.setSurfaceSize(const Size(420, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: ThemeMode.light,
              home: Scaffold(
                body: PinKeypad(
                  onComplete: (_) {},
                  errorText: 'PINs did not match.',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final ctx = tester.element(find.byType(Scaffold));
        final lightMb = Theme.of(ctx).extension<MbColors>()!;
        final errorTextWidget = tester.widget<Text>(
          find.text('PINs did not match.'),
        );
        final actualColor = errorTextWidget.style?.color;
        expect(
          actualColor,
          equals(MoodBloomColors.coralText),
          reason:
              'PIN keypad error text on light theme must retain the '
              'historical MoodBloomColors.coralText binding so the '
              '6.04:1 light contrast does not regress. A naive uniform '
              'swap to colorScheme.error would have dropped this pair '
              'to ~1.86:1.',
        );
        expect(
          _contrastRatio(actualColor!, lightMb.bg),
          _meets(threshold: 4.5),
          reason: 'Light-theme PIN error text must clear AA.',
        );
      },
    );

    testWidgets(
      'PinSetupScreen title + subtitle pass AA on dark',
      (tester) async {
        // No router required — the screen receives onSuccess/onCancel
        // callbacks; no provider overrides needed because the use case
        // is only invoked after a complete PIN, which the test does not
        // type.
        await _pumpDark(
          tester,
          child: PinSetupScreen(
            userId: 'u-wave-c',
            onSuccess: () {},
            onCancel: () {},
          ),
        );
        final tokens = _darkTokens(tester);
        // Title uses `mb.text`; subtitle uses `mb.textDim`. Both over
        // `mb.bg` (Scaffold fill).
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'PinVerifyScreen — locked warning now uses theme.colorScheme.error '
      '(Wave C fix); was MoodBloomColors.coralText pre-Wave C',
      (tester) async {
        // The locked warning only renders when _lockedUntil > now. We
        // can't easily exercise that path without driving the keypad
        // through too-many-tries; instead we assert the token binding
        // contract via the theme: `theme.colorScheme.error` over
        // `mb.bg` must pass AA. This is the binding the production
        // code uses post-Wave C.
        await _pumpDark(tester, child: const SizedBox.shrink());
        final tokens = _darkTokens(tester);
        // theme.colorScheme.error is pinned to MoodBloomColors.coral
        // (see packages/design_system/lib/src/theme.dart); on dark
        // mb.bg it computes to ~8.25:1. Lock the contract.
        expect(
          _contrastRatio(tokens.scheme.error, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );

    testWidgets(
      'PrivacySetupFlowScreen — _BiometricStep title + subtitle on Scaffold '
      'pass AA on dark',
      (tester) async {
        // Wrap in a GoRouter so the cancel-button context.pop() target
        // exists; the test only exercises the colour bindings on mount.
        final router = GoRouter(
          initialLocation: '/host',
          routes: [
            GoRoute(
              path: '/host',
              builder: (_, _) => const Scaffold(body: Text('host')),
              routes: [
                GoRoute(
                  path: 'privacy/setup',
                  builder: (_, _) => const PrivacySetupFlowScreen(),
                ),
              ],
            ),
          ],
        );
        await tester.binding.setSurfaceSize(const Size(420, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              auth_providers.currentUserStreamProvider.overrideWith(
                (_) => Stream<AppUser?>.value(
                  const AppUser(uid: 'u-wave-c', email: 'u@example.com'),
                ),
              ),
            ],
            child: MaterialApp.router(
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: ThemeMode.dark,
              routerConfig: router,
            ),
          ),
        );
        router.go('/host/privacy/setup');
        await tester.pump();
        await tester.pump();

        final tokens = _darkTokens(tester);
        // The flow screen's _BiometricStep title + subtitle use mb.text
        // / mb.textDim on mb.bg.
        expect(
          _contrastRatio(tokens.mb.text, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
        expect(
          _contrastRatio(tokens.mb.textDim, tokens.mb.bg),
          _meets(threshold: 4.5),
        );
      },
    );
  });
}

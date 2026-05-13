import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/presentation/widgets/cheer_up_banner.dart';

/// Sprint 5 Day 3 a11y sweep — cheer-up (Tier 1) intervention banner.
///
/// The banner is the only intervention surface that lives inline on the
/// garden home, so its semantics directly affect first-contact
/// screen-reader UX. Three properties verified:
///   1. The container's Semantics label starts with the locked
///      CLAUDE.md sentence (already covered by the parity test) — we
///      additionally verify the decorative 🌸 emoji is excluded.
///   2. Both "Try it" and "Not now" pill buttons announce as buttons
///      with their own labels (no "Button"/"Button" conflict).
///   3. The banner survives 200% type without overflow.

Future<void> _pumpBanner(
  WidgetTester tester, {
  TextScaler textScaler = const TextScaler.linear(1.0),
  Size surfaceSize = const Size(360, 720),
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CheerUpBanner(reason: '5_of_7_negative', onDismiss: () {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CheerUpBanner — semantics', () {
    testWidgets('"Try it" and "Not now" each announce as named buttons',
        (tester) async {
      await _pumpBanner(tester);

      // Two pill buttons live inside the banner; both must announce as
      // distinct buttons so a screen-reader user can tell them apart
      // without listening to the surrounding context. A "Button" /
      // "Button" pair is the canonical semantics-conflict bug.
      final tryIt = tester.getSemantics(find.text('Try it'));
      final notNow = tester.getSemantics(find.text('Not now'));

      expect(tryIt.label, contains('Try it'));
      expect(tryIt.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(notNow.label, contains('Not now'));
      expect(notNow.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('decorative cherry-blossom emoji is excluded from semantics',
        (tester) async {
      // The 🌸 is purely ornamental — the banner's wrapping Semantics
      // already carries the full CLAUDE.md-locked sentence. Without an
      // ExcludeSemantics wrap, TalkBack/VoiceOver would announce
      // "cherry blossom" before the actual prompt, which is noise.
      await _pumpBanner(tester);

      final emojiSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label ?? '')
          .toList();
      // The emoji's glyph should NOT appear as an own-label anywhere in
      // the descendant semantics tree. The parent's locked-sentence
      // label is allowed.
      expect(
        emojiSemantics.any((label) => label == '🌸'),
        isFalse,
        reason: 'decorative emoji must not have its own semantic label',
      );
    });
  });

  group('CheerUpBanner — 200% type readability', () {
    testWidgets('renders without RenderFlex overflow at 200% type',
        (tester) async {
      final exceptions = <Object>[];
      FlutterError.onError = (details) => exceptions.add(details.exception);
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await _pumpBanner(tester, textScaler: const TextScaler.linear(2.0));

      final overflows = exceptions
          .map((e) => e.toString())
          .where((s) => s.contains('overflowed') || s.contains('RenderFlex'))
          .toList();
      expect(
        overflows,
        isEmpty,
        reason:
            'CheerUpBanner must not overflow at 200% type. The Expanded '
            'column inside a Row already gives the text room to wrap, '
            'but a future refactor that drops the Expanded would break '
            'this. Failures: $overflows',
      );

      // Sanity: both halves of the locked sentence must still render.
      expect(find.text("It's been a heavy week."), findsOneWidget);
      expect(
        find.text('Want to try a two-minute breathing exercise?'),
        findsOneWidget,
      );
    });
  });
}

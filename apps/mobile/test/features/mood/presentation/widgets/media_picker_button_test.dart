import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/repositories/mood_media_repository.dart';
import 'package:moodbloom/features/mood/presentation/widgets/media_picker_button.dart';

/// Pumps [MediaPickerButton] inside a minimal [MaterialApp]. The platform
/// is forced via [debugDefaultTargetPlatformOverride] so we can exercise
/// the desktop / mobile branches deterministically. `kIsWeb` itself is a
/// compile-time constant and cannot be overridden - the macOS path below
/// stands in for "desktop-like" (web + Windows + macOS + Linux).
///
/// Note on platform restoration: Flutter's `_verifyInvariants` runs at
/// the end of the test body - BEFORE `tearDown` and `addTearDown`
/// callbacks. Setting `debugDefaultTargetPlatformOverride = null` from
/// either of those hooks is therefore too late and trips the
/// "value of a foundation debug variable was changed" assertion. Each
/// test below uses a try/finally inline so the override is cleared
/// before the test body returns.
Future<void> _pump(
  WidgetTester tester, {
  required bool wideLayout,
  required ValueChanged<MoodMediaSource> onPick,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MediaPickerButton(onPick: onPick, wideLayout: wideLayout),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Run [body] with [debugDefaultTargetPlatformOverride] pinned to
/// [platform], guaranteeing the override is cleared before the test
/// body returns (so Flutter's invariant check passes).
Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  group('MediaPickerButton', () {
    group('mobile (Android) - camera + gallery icon row', () {
      testWidgets('narrow layout: shows BOTH camera and gallery icons', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.android, () async {
          await _pump(tester, wideLayout: false, onPick: (_) {});

          expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
          expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
          expect(
            find.byType(OutlinedButton),
            findsNothing,
            reason:
                'mobile platforms must keep the compact icon row, not the '
                'desktop full-width outlined button',
          );
        });
      });

      testWidgets(
        'wide layout: still shows BOTH icons (tablet still has a camera)',
        (tester) async {
          await _withPlatform(TargetPlatform.android, () async {
            await _pump(tester, wideLayout: true, onPick: (_) {});

            expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
            expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
            expect(find.byType(OutlinedButton), findsNothing);
          });
        },
      );

      testWidgets('tapping the camera icon emits MoodMediaSource.camera', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.android, () async {
          MoodMediaSource? captured;
          await _pump(tester, wideLayout: false, onPick: (s) => captured = s);

          await tester.tap(find.byIcon(Icons.camera_alt_outlined));
          await tester.pumpAndSettle();

          expect(captured, equals(MoodMediaSource.camera));
        });
      });
    });

    group('desktop-like (macOS stand-in) - single source only', () {
      testWidgets('narrow layout: hides the camera icon, keeps gallery only', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.macOS, () async {
          await _pump(tester, wideLayout: false, onPick: (_) {});

          expect(
            find.byIcon(Icons.camera_alt_outlined),
            findsNothing,
            reason:
                'on desktop / web image_picker maps both sources to the '
                'OS file dialog - surfacing camera is misleading',
          );
          // Either the photo_library icon (legacy mobile gallery glyph)
          // OR the image_outlined glyph used by the desktop variant. The
          // desktop branch picks the latter.
          expect(find.byIcon(Icons.image_outlined), findsOneWidget);
          expect(find.byType(OutlinedButton), findsNothing);
        });
      });

      testWidgets(
        'wide layout: promotes to a single full-width "Attach a photo" button',
        (tester) async {
          await _withPlatform(TargetPlatform.macOS, () async {
            await _pump(tester, wideLayout: true, onPick: (_) {});

            expect(find.byType(OutlinedButton), findsOneWidget);
            expect(find.text('Attach a photo'), findsOneWidget);
            expect(
              find.byIcon(Icons.camera_alt_outlined),
              findsNothing,
              reason:
                  'desktop wide layout must NOT surface the camera affordance',
            );
          });
        },
      );

      testWidgets('wide-layout button taps emit MoodMediaSource.gallery', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.macOS, () async {
          MoodMediaSource? captured;
          await _pump(tester, wideLayout: true, onPick: (s) => captured = s);

          await tester.tap(find.byType(OutlinedButton));
          await tester.pumpAndSettle();

          expect(
            captured,
            equals(MoodMediaSource.gallery),
            reason:
                'on desktop the only path through image_picker is the OS '
                'file dialog, which we route through MoodMediaSource.gallery',
          );
        });
      });
    });
  });
}

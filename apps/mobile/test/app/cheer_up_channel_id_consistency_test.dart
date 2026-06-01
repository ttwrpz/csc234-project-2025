import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static cross-site check for the FCM Android notification channel id
/// `cheer_up`. PR #35 audit R-006 - this literal MUST be byte-identical
/// at three sites or the cheer-up push pipeline breaks silently:
///
///   1. AndroidManifest.xml meta-data - the system-fallback channel
///      Android uses if a notification arrives with no client-side
///      registration.
///   2. main.dart channel registration - the real `AndroidNotificationChannel`
///      registered at app boot via `flutter_local_notifications`.
///   3. functions/src/sendCheerUpPush.ts payload - the channelId the CF
///      sends in the FCM multicast.
///
/// A typo on any one of the three (`cheerUp`, `cheer-up`, `cheer_Up`)
/// collapses delivery on Android 8+ without raising any error visible to
/// the developer. Manual review caught the alignment in PR #35; this
/// test is the automated guardrail that prevents drift.
///
/// Why a Dart test under `apps/mobile/test/`: the rule needs to read
/// files outside `apps/mobile/lib/` (the manifest + the CF source). The
/// Dart test runner is the only place in the project that can do that
/// with cross-platform path resolution. Functions Jest is scoped to
/// `functions/src/`; the rules emulator suite tests rules only.
void main() {
  const expectedChannelId = 'cheer_up';

  // Locate the repo root by walking upward from the test file's
  // working directory until we find `apps/mobile/pubspec.yaml`. This
  // makes the test resilient to whatever cwd `flutter test` chooses.
  Directory findRepoRoot() {
    var dir = Directory.current;
    for (var i = 0; i < 8; i += 1) {
      final probe = File('${dir.path}/apps/mobile/pubspec.yaml');
      if (probe.existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    // Fall back to cwd, which works when `flutter test` runs from
    // apps/mobile/.
    return Directory.current.parent.parent;
  }

  final repoRoot = findRepoRoot();

  group('Channel id `cheer_up` byte-identical across three sites', () {
    test('1. AndroidManifest.xml declares the channel id meta-data', () {
      final manifest = File(
        '${repoRoot.path}/apps/mobile/android/app/src/main/AndroidManifest.xml',
      );
      expect(
        manifest.existsSync(),
        isTrue,
        reason: 'manifest must exist at the documented path',
      );
      final body = manifest.readAsStringSync();
      expect(
        body.contains(
          'android:name="com.google.firebase.messaging.default_notification_channel_id"',
        ),
        isTrue,
        reason:
            'manifest must declare the FCM default-channel meta-data so '
            'Android knows which channel to use when a notification '
            'arrives with no client-side registration',
      );
      expect(
        body.contains('android:value="$expectedChannelId"'),
        isTrue,
        reason: 'manifest meta-data value must be exactly "$expectedChannelId"',
      );
    });

    test('2. main.dart registers the AndroidNotificationChannel', () {
      final mainDart = File('${repoRoot.path}/apps/mobile/lib/main.dart');
      expect(mainDart.existsSync(), isTrue);
      final body = mainDart.readAsStringSync();
      expect(
        body.contains('AndroidNotificationChannel('),
        isTrue,
        reason:
            'main.dart must construct an AndroidNotificationChannel via '
            'flutter_local_notifications at boot',
      );
      // RegExp.escape via raw-string + literal - channel id literal must
      // be the FIRST positional arg of an AndroidNotificationChannel
      // call. `\\s*'cheer_up'` after the open paren tolerates any
      // amount of formatter-inserted whitespace (newline, indent).
      final reChannelArg = RegExp(
        r"AndroidNotificationChannel\(\s*'" + expectedChannelId + r"'",
      );
      expect(
        reChannelArg.hasMatch(body),
        isTrue,
        reason:
            'main.dart channel id literal must be the first arg of '
            "AndroidNotificationChannel - exactly '$expectedChannelId'",
      );
    });

    test('3. functions/src/sendCheerUpPush.ts pins CHANNEL_ID', () {
      final cf = File('${repoRoot.path}/functions/src/sendCheerUpPush.ts');
      expect(cf.existsSync(), isTrue);
      final body = cf.readAsStringSync();
      expect(
        body.contains("const CHANNEL_ID = '$expectedChannelId';"),
        isTrue,
        reason:
            'sendCheerUpPush.ts must declare `const CHANNEL_ID = '
            '\'$expectedChannelId\'` exactly so the multicast payload '
            'carries the matching channel id',
      );
    });
  });
}

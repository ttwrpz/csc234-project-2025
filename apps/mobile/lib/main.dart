import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/bootstrap.dart';
import 'features/settings/data/theme_mode_storage.dart';
import 'features/settings/presentation/controllers/theme_mode_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics — capture both Flutter framework errors and async errors
      // from the platform dispatcher. Disabled in debug so dev crashes never
      // pollute the production console.
      //
      // Skipped on Web: firebase_crashlytics has no Web implementation; even
      // touching `FirebaseCrashlytics.instance` (e.g. via
      // `setCrashlyticsCollectionEnabled`) trips an assertion in the platform
      // interface (`pluginConstants['isCrashlyticsCollectionEnabled'] != null`)
      // because no Web plugin is registered. We gracefully no-op on Web —
      // unhandled errors still surface in the browser console; production
      // crash reporting on Web is a S5 follow-up (Sentry or similar).
      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
      }

      // Remote Config — register defaults synchronously so flag reads return
      // sane values even before the first fetchAndActivate completes. The
      // 60-min `minimumFetchInterval` matches CLAUDE.md "Feature flag
      // (rollback plan)" — production clients pick up server-side flips
      // within an hour. Lowered briefly to 60s for the v1.0 demo (kickoff
      // Open Question O-3); restored here in the v1.0.1 patch as documented
      // in `docs/runbooks/feature-flag-rollback.md` §"Restoring the
      // 60-minute interval".
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(<String, Object>{
        'ai_pattern_analysis_enabled': true,
        'gemini_detection_enabled': true,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 60),
        ),
      );
      // Fire-and-forget — must not block app startup.
      unawaited(rc.fetchAndActivate());

      // FCM cheer-up channel (HB-003 §5.5b R-001 closure). Without
      // this, Android 8+ silently drops notifications attached to the
      // `cheer_up` channel id — the FCM SDK falls back to the channel
      // declared in AndroidManifest.xml, but only if it's been created
      // by the app at least once. Channel id MUST match the manifest
      // meta-data (`com.google.firebase.messaging.default_notification_channel_id`)
      // and the Cloud Function payload (`functions/src/sendCheerUpPush.ts`)
      // — all three are the literal string `'cheer_up'`. Skipped on
      // Web because flutter_local_notifications has no Web impl; the
      // browser FCM service worker handles its own notification UX.
      if (!kIsWeb) {
        const androidChannel = AndroidNotificationChannel(
          'cheer_up',
          'Cheer-up check-ins',
          description: 'Gentle reminders during heavier stretches.',
          importance: Importance.defaultImportance,
        );
        await FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidChannel);
      }

      // google_sign_in 7.x requires `initialize()` to be called exactly
      // once before any other method, with its Future awaited. Skipped
      // on Web because we use Firebase's `signInWithPopup` directly
      // (see firebase_auth_datasource.dart §kIsWeb branch); the v7
      // `google_sign_in_web` flow needs an OAuth client id that we
      // don't currently configure for web. `clientId` and
      // `serverClientId` are intentionally null — the Android plugin
      // reads from `google-services.json` and iOS reads from
      // `GoogleService-Info.plist`, both already in place from
      // `flutterfire configure`.
      if (!kIsWeb) {
        await GoogleSignIn.instance.initialize();
      }

      // Eager-resolve SharedPreferences before runApp so the theme-mode
      // controller has its persisted value on the very first frame —
      // avoids the flash-of-light that an AsyncValue.loading would
      // produce. The cost is a single async call at startup; the
      // benefit is a settled theme on cold launch.
      final prefs = await SharedPreferences.getInstance();
      final themeStorage = ThemeModeStorage(prefs);

      runApp(
        ProviderScope(
          overrides: [
            themeModeControllerProvider.overrideWith(
              () => ThemeModeController(storage: themeStorage),
            ),
          ],
          child: const MoodBloomApp(),
        ),
      );
    },
    (error, stack) {
      // Web: no-op (Crashlytics has no Web impl). Native: forward to
      // Crashlytics so async-zone unhandled errors are recorded.
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

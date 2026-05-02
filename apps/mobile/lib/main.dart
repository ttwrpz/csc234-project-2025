import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // sane values even before the first fetchAndActivate completes.
      //
      // `minimumFetchInterval` is lowered to 60s for the v1.0 demo per kickoff
      // Open Question O-3 — the demo's kill-switch rehearsal acceptance bar
      // requires the Pattern Insights card to hide within 60s of flipping
      // `ai_pattern_analysis_enabled`. **Restored to 60min in the v1.0.1
      // patch** (see `docs/runbooks/feature-flag-rollback.md` §"Restoring the
      // 60-minute interval"). Hundreds of production clients would flood RC
      // at this cadence; the lowered interval is demo-only.
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(<String, Object>{
        'ai_pattern_analysis_enabled': true,
        'gemini_detection_enabled': true,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 60),
        ),
      );
      // Fire-and-forget — must not block app startup.
      unawaited(rc.fetchAndActivate());

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

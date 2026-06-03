import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/bootstrap.dart';
import 'app/providers.dart' show sharedPreferencesProvider;
import 'features/auth/data/datasources/biometric_datasource.dart';
import 'features/auth/data/datasources/biometric_preference_datasource.dart';
import 'features/auth/data/datasources/privacy_lock_preference_datasource.dart';
import 'features/auth/data/providers.dart';
import 'features/auth/data/repositories/biometric_repository_impl.dart';
import 'features/auth/domain/entities/biometric_capability.dart';
import 'features/settings/data/theme_mode_storage.dart';
import 'features/settings/presentation/controllers/theme_mode_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Web: clean path-based URLs (e.g. /home instead of /#/home) so deep
      // links and the address bar read naturally. No-op on native.
      if (kIsWeb) usePathUrlStrategy();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Explicit Firestore settings - make the offline cache durable
      // across hot restarts and force a generous cache budget so
      // reads keep working when the gRPC channel is briefly wedged
      // (Samsung Android can leave the channel in a "Unable to resolve
      // host" state after hot restart even though DNS is healthy).
      // Setting `settings` MUST happen before the first Firestore
      // call - runs here right after Firebase.initializeApp.
      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      // Crashlytics - capture both Flutter framework errors and async errors
      // from the platform dispatcher.
      //
      // Collection is ALWAYS enabled (including debug). The
      // Settings → Debug → "Crash now" affordance only renders in
      // debug builds, so gating on `!kDebugMode` meant QA could crash
      // the app but the dashboard never received the report,
      // defeating the affordance's only purpose. Crashlytics writes
      // the report locally on crash and uploads on the NEXT app
      // launch - to see your test crash in the dashboard, reopen the
      // app after tapping "Crash now". Real dev-time framework
      // exceptions still print to the console; they also upload,
      // which is a small extra noise floor we accept in exchange for
      // a working verify-wiring path.
      //
      // Skipped on Web: firebase_crashlytics has no Web implementation;
      // even touching `FirebaseCrashlytics.instance` (e.g. via
      // `setCrashlyticsCollectionEnabled`) trips an assertion in the
      // platform interface
      // (`pluginConstants['isCrashlyticsCollectionEnabled'] != null`)
      // because no Web plugin is registered. We gracefully no-op on
      // Web - unhandled errors still surface in the browser console.
      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
      }

      // Remote Config - register defaults synchronously so flag reads return
      // sane values even before the first fetchAndActivate completes. The
      // 60-min `minimumFetchInterval` matches CLAUDE.md "Feature flag
      // (rollback plan)" - production clients pick up server-side flips
      // within an hour.
      final rc = FirebaseRemoteConfig.instance;
      // Defaults MUST stay in sync with `FeatureFlags.defaults()` in
      // `apps/mobile/lib/app/feature_flags.dart` AND with the canonical
      // template at `firebase/remoteconfig.template.json` (deployed
      // via `firebase deploy --only remoteconfig`).
      await rc.setDefaults(<String, Object>{
        'ai_pattern_analysis_enabled': true,
        'gemini_detection_enabled': true,
        // Default false: the client-side Pattern Engine writes
        // patterns/{date} regardless, but no notification fires until
        // the dispatcher reading patterns/{date}.triggeredTier ships.
        'intervention_dispatch_enabled': false,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 60),
        ),
      );
      // Fire-and-forget - must not block app startup.
      unawaited(rc.fetchAndActivate());

      // FCM cheer-up channel. Without this, Android 8+ silently drops
      // notifications attached to the `cheer_up` channel id - the FCM
      // SDK falls back to the channel declared in AndroidManifest.xml,
      // but only if it's been created by the app at least once. Channel
      // id MUST match the manifest meta-data
      // (`com.google.firebase.messaging.default_notification_channel_id`)
      // and the Cloud Function payload (`functions/src/sendCheerUpPush.ts`)
      // - all three are the literal string `'cheer_up'`. Skipped on
      // Web because flutter_local_notifications has no Web impl; the
      // browser FCM service worker handles its own notification UX.
      if (!kIsWeb) {
        final plugin = FlutterLocalNotificationsPlugin();
        // The plugin MUST be `.initialize`d before any other call
        // (`requestNotificationsPermission`, `show`, channel ops) on
        // Android. Without initialize, the Android binding is never
        // wired up and `requestNotificationsPermission()` silently
        // returns `null` instead of triggering the OS POST_NOTIFICATIONS
        // dialog - which manifests as "the onboarding notification
        // toggle never prompts." Icon reference matches AndroidManifest's
        // `android:icon` so the OS uses the right asset on the system
        // tray when the cheer-up channel fires.
        await plugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );

        const androidChannel = AndroidNotificationChannel(
          'cheer_up',
          'Cheer-up check-ins',
          description: 'Gentle reminders during heavier stretches.',
          importance: Importance.defaultImportance,
        );
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidChannel);
      }

      // google_sign_in 7.x requires `initialize()` to be called exactly
      // once before any other method, with its Future awaited. Skipped
      // on Web because we use Firebase's `signInWithPopup` directly.
      //
      // `serverClientId` MUST be the Web OAuth client_id from
      // google-services.json (the entry under `oauth_client` with
      // `client_type: 3`). On Android the v7 plugin drives Credential
      // Manager, which needs an audience to issue the idToken for; with
      // a null serverClientId, Credential Manager picks a random
      // matching client - and when no SHA-1-bound Android OAuth client
      // exists in the Firebase project, it silently returns
      // `GoogleSignInExceptionCode.canceled` AFTER the user picks an
      // account, which surfaces as "Google sign-in was cancelled" even
      // though the user didn't cancel. Passing the Web client_id
      // explicitly tells Credential Manager to issue the idToken with
      // Firebase's audience, and `signInWithCredential` accepts it.
      //
      // Keep this string in sync with google-services.json. If you
      // re-run `flutterfire configure` and the project_number changes,
      // update the client_id below too.
      if (!kIsWeb) {
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '433750563013-v71cgbqggb100qvjkiu2sqn8a83veoj1.apps.googleusercontent.com',
        );
      }

      // Eager-resolve SharedPreferences before runApp so the theme-mode
      // controller has its persisted value on the very first frame -
      // avoids the flash-of-light that an AsyncValue.loading would
      // produce. The cost is a single async call at startup; the
      // benefit is a settled theme on cold launch.
      final prefs = await SharedPreferences.getInstance();
      final themeStorage = ThemeModeStorage(prefs);

      // Pre-resolve Privacy Lock state BEFORE runApp so the router
      // redirect reads synchronous values on the very first pass.
      // Without this, the biometric capability provider is a
      // FutureProvider whose `.value` is `null` on first redirect, the
      // gate is skipped, and the user sees the home screen for one
      // frame before the gate fires. ~50–150 ms added to cold start;
      // worth it for a settled first frame.
      //
      // On Web `local_auth` throws on every call (no platform impl),
      // so we wrap the capability lookup and fall back to "unavailable"
      // - the unlock screen handles that gracefully (PIN-only).
      // SharedPreferences is platform-safe on every supported target.
      BiometricCapability cap = const BiometricCapability(
        isAvailable: false,
        hasEnrolledBiometrics: false,
        userOptedIn: false,
      );
      try {
        final biometricRepo = BiometricRepositoryImpl(
          datasource: BiometricDatasource(),
          preference: BiometricPreferenceDatasource(prefs),
        );
        cap = await biometricRepo.capability();
      } catch (_) {
        // Web (no local_auth impl) or transient platform failure -
        // fall back to the unavailable record so the unlock screen
        // shows the PIN keypad only.
      }
      final privacyLockEnabled = PrivacyLockPreferenceDatasource(
        prefs,
      ).isEnabled();

      // One-shot migration marker. Flips the marker forward without
      // mutating any existing keys - old `auth.biometric_enabled` and
      // `auth.privacy_lock_enabled` keep their values, and the unified
      // tile in Settings now reads both correctly. Existing biometric-
      // only users will see Privacy Lock OFF (no PIN was ever set);
      // they re-enable via the unified tile, which now bundles PIN +
      // biometric in one setup flow.
      const privacyLockV2MigratedKey = 'auth.privacy_lock_v2_migrated';
      if (!(prefs.getBool(privacyLockV2MigratedKey) ?? false)) {
        await prefs.setBool(privacyLockV2MigratedKey, true);
      }

      runApp(
        ProviderScope(
          overrides: [
            themeModeControllerProvider.overrideWith(
              () => ThemeModeController(storage: themeStorage),
            ),
            biometricCapabilityProvider.overrideWith((ref) async => cap),
            privacyLockEnabledProvider.overrideWith(
              () => SeededPrivacyLockEnabledNotifier(privacyLockEnabled),
            ),
            // Seed the already-resolved SharedPreferences so the very first
            // read of `sharedPreferencesProvider` returns synchronously.
            // `moodSyncManagerProvider` throws when `.value` is null, and on
            // mobile cold-boot the router's auth listener is the FIRST reader
            // of both providers - without this seed that read throws, the
            // sync manager is never bootstrapped (no listener, no drain), and
            // queued mood writes never reach Firestore ("never synced").
            // Returns `prefs` synchronously (NOT `async`) so the override is
            // AsyncData immediately - an async callback would resolve on a
            // microtask and `.value` would still be null on the first read.
            sharedPreferencesProvider.overrideWith((ref) => prefs),
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

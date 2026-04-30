import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/data/providers.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/biometric_gate_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/widgets/biometric_settings_tile.dart';
import '../features/garden/presentation/garden_screen.dart';
import '../features/history/presentation/entry_detail_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/mood/data/providers.dart' as mood_providers;
import '../features/mood/presentation/log_mood_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';

const _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AppUser?>(null);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (previous, next) {
    refresh.value = next.valueOrNull;

    final prevUid = previous?.valueOrNull?.uid;
    final nextUid = next.valueOrNull?.uid;

    // PR-3: drive the MoodSyncManager lifecycle off auth-state transitions.
    // Sign-in (or auth resolves with a non-null user on app start) → bootstrap
    // the sync manager so Drift is seeded once per uid and the live listener
    // attaches. Sign-out → shutdown so the previous user's listener and timers
    // are torn down before another sign-in re-attaches.
    final manager = ref.read(mood_providers.moodSyncManagerProvider);
    if (nextUid != null && nextUid != prevUid) {
      // ignore: discarded_futures
      manager.bootstrap(nextUid);
    } else if (nextUid == null && prevUid != null) {
      // ignore: discarded_futures
      manager.shutdown();
    }

    // 2.2: on sign-out (non-null → null), clear the session-scoped biometric
    // unlock flag so a future re-sign-in re-prompts. Correct security
    // behaviour: a fresh login should re-verify biometric on cold boot.
    if (previous?.valueOrNull != null && next.valueOrNull == null) {
      ref.read(biometricUnlockedThisSessionProvider.notifier).state = false;
    }
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(_onboardingCompleteKey) ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/sign-in' || loc == '/sign-up';

      // 1. Onboarding gate (preserved from 6.1).
      if (!onboardingDone && loc != '/onboarding') return '/onboarding';
      if (onboardingDone && loc == '/onboarding') {
        return refresh.value == null ? '/sign-in' : '/home';
      }
      // 2. Auth gate.
      if (onboardingDone && refresh.value == null && !isAuthRoute) {
        return '/sign-in';
      }
      if (refresh.value != null && isAuthRoute) return '/home';

      // 3. Biometric gate (WBS 2.2). Only inserts itself when (a) the user
      // is signed in, (b) capability + opt-in are present AND ready
      // synchronously, and (c) we haven't already unlocked this session.
      // We avoid awaiting the FutureProvider here to keep redirects fast —
      // if capability hasn't resolved yet, we let the user through and the
      // gate will only kick in on the next router refresh once data lands.
      if (refresh.value != null &&
          loc != '/biometric-gate' &&
          !ref.read(biometricUnlockedThisSessionProvider)) {
        final cap = ref.read(biometricCapabilityProvider).valueOrNull;
        if (cap != null && cap.shouldGate) {
          return '/biometric-gate';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/biometric-gate',
        builder: (context, state) => const BiometricGateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (c, s) => const GardenScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (c, s) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (c, s) =>
                        EntryDetailScreen(id: s.pathParameters['id'] ?? ''),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log-mood',
                builder: (c, s) => const LogMoodScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (c, s) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const _SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SettingsScreen extends ConsumerWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final displayName = user?.displayName;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(user.email ?? 'Signed in'),
              subtitle: displayName == null ? null : Text(displayName),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(signOutUseCaseProvider)();
            },
          ),
          const SizedBox(height: MoodBloomSpacing.lg),
          const BiometricSettingsTile(),
          if (kDebugMode) ...[
            const SizedBox(height: MoodBloomSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MoodBloomSpacing.lg,
              ),
              child: FilledButton.tonal(
                onPressed: () {
                  // Debug-only escape hatch for verifying the Crashlytics
                  // wiring end-to-end. Stripped in release builds via
                  // kDebugMode.
                  throw Exception(
                    'Crashlytics test crash from Settings — debug only',
                  );
                },
                child: const Text('Crash now (debug)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

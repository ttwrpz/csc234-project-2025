import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import 'providers.dart';

import '../features/auth/data/history_unlocked_this_session_provider.dart';
import '../features/auth/data/providers.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/biometric_gate_screen.dart';
import '../features/auth/presentation/screens/pin_verify_screen.dart';
import '../features/auth/presentation/screens/privacy_setup_flow_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/garden/presentation/garden_screen.dart';
import '../features/history/presentation/entry_detail_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/insights/presentation/screens/insights_screen.dart';
import '../features/intervention/domain/entities/intervention_dispatch.dart';
import '../features/intervention/presentation/screens/breathing_screen.dart';
import '../features/intervention/presentation/screens/crisis_resources_screen.dart';
import '../features/intervention/presentation/screens/journaling_prompt_screen.dart';
import '../features/mood/data/providers.dart' as mood_providers;
import '../features/mood/presentation/log_mood_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/domain/entities/theme_mode_preference.dart';
import '../features/settings/presentation/controllers/theme_mode_controller.dart';
import 'widgets/mb_bottom_nav.dart';
import 'widgets/mb_side_nav.dart';

const _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AppUser?>(null);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (previous, next) {
    refresh.value = next.value;

    final prevUid = previous?.value?.uid;
    final nextUid = next.value?.uid;

    // PR-3: drive the MoodSyncManager lifecycle off auth-state transitions.
    // Sign-in (or auth resolves with a non-null user on app start) → bootstrap
    // the sync manager so Drift is seeded once per uid and the live listener
    // attaches. Sign-out → shutdown so the previous user's listener and timers
    // are torn down before another sign-in re-attaches.
    //
    // Skipped on Web: Drift's native connector is unavailable there
    // (ADR-0004 §"Risks #1"). The repository's offlineFirstEnabledProvider
    // already defaults to `!kIsWeb`, so reads/writes route through Firestore
    // directly; bootstrapping the sync manager would only open a DB that
    // throws on first query.
    if (!kIsWeb) {
      final manager = ref.read(mood_providers.moodSyncManagerProvider);
      if (nextUid != null && nextUid != prevUid) {
        // ignore: discarded_futures
        manager.bootstrap(nextUid);
      } else if (nextUid == null && prevUid != null) {
        // ignore: discarded_futures
        manager.shutdown();
      }
    }

    // 2.2: on sign-out (non-null → null), clear the session-scoped biometric
    // unlock flag so a future re-sign-in re-prompts. Correct security
    // behaviour: a fresh login should re-verify biometric on cold boot.
    // ADR-0013: the History privacy unlock is cleared on the same edge,
    // so a fresh sign-in always re-prompts on the History route.
    if (previous?.value != null && next.value == null) {
      ref.read(biometricUnlockedThisSessionProvider.notifier).state = false;
      ref.read(historyUnlockedThisSessionProvider.notifier).lock();
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
        final cap = ref.read(biometricCapabilityProvider).value;
        if (cap != null && cap.shouldGate) {
          return '/biometric-gate';
        }
      }

      // 4. History privacy gate (ADR-0013). Guards `/history` and any
      // sub-route (`/history/:id` and future deep links). Mirrors the
      // existing cold-boot biometric gate pattern: gracefully exits
      // when any precondition isn't ready (no flag, no opt-in, no
      // PIN). Open Follow-up #2: the redirect must not loop —
      // `/unlock-history` itself short-circuits the gate, and the
      // `/privacy/setup` modal route is also exempt so toggling
      // ON during setup doesn't fire the gate on a Settings-sourced
      // visit.
      final isHistoryRoute = loc == '/history' || loc.startsWith('/history/');
      final isUnlockRoute = loc == '/unlock-history';
      final isPrivacySetup = loc == '/privacy/setup';
      if (isHistoryRoute && !isUnlockRoute && !isPrivacySetup) {
        final flags = ref.read(featureFlagsProvider);
        final userOptedIn = ref.read(privacyLockEnabledProvider);
        if (flags.historyPrivacyLockEnabled && userOptedIn) {
          final unlock = ref.read(historyUnlockedThisSessionProvider);
          final unlocked = unlock.isUnlocked(now: DateTime.now().toUtc());
          if (!unlocked) {
            return '/unlock-history?returnTo=${Uri.encodeComponent(loc)}';
          }
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
      // ADR-0013 — History privacy gate (biometric + PIN fallback).
      // Reachable via the redirect clause #4 above when the user has
      // opted in. `returnTo` is URL-encoded by the redirect so any
      // `/history/<id>` deep link survives the round-trip.
      GoRoute(
        path: '/unlock-history',
        builder: (context, state) {
          final returnTo = state.uri.queryParameters['returnTo'];
          return PinVerifyScreen(returnTo: returnTo);
        },
      ),
      // ADR-0013 Decision G — first-time setup flow for the History
      // privacy gate. Modal route reached via Settings → PRIVACY →
      // "Set up PIN" or by flipping the master switch ON. Pops with
      // `true` on success and `false` on cancellation.
      GoRoute(
        path: '/privacy/setup',
        builder: (context, state) => const PrivacySetupFlowScreen(),
      ),
      // Intervention surfaces — full-screen routes opened from the
      // [InterventionBanner] (or the FCM notification tap-action when
      // background dispatch lands). Each route accepts the
      // [InterventionDispatch] via `state.extra` so the screen renders
      // the dispatcher-composed body verbatim; deep-link visits with no
      // extra fall back to the [DispatchSafeDefaults] constants.
      // Authorized by the engineer brief; HB-007 §"Files to extend".
      GoRoute(
        path: '/intervention/breathing',
        name: 'intervention.breathing',
        builder: (context, state) {
          final dispatch = state.extra is InterventionDispatch
              ? state.extra as InterventionDispatch
              : null;
          return BreathingScreen(dispatch: dispatch);
        },
      ),
      GoRoute(
        path: '/intervention/journal',
        name: 'intervention.journal',
        builder: (context, state) {
          final dispatch = state.extra is InterventionDispatch
              ? state.extra as InterventionDispatch
              : null;
          return JournalingPromptScreen(dispatch: dispatch);
        },
      ),
      GoRoute(
        path: '/intervention/crisis',
        name: 'intervention.crisis',
        builder: (context, state) {
          final dispatch = state.extra is InterventionDispatch
              ? state.extra as InterventionDispatch
              : null;
          return CrisisResourcesScreen(dispatch: dispatch);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        // Bottom-nav order: Home / History / Log (highlighted, centre) /
        // Patterns / Settings. Putting Log at the geometric centre with a
        // primary-coloured halo makes the most-frequent action obvious to
        // first-time users; History and Patterns keep their nav slots but
        // swap positions vs the original prototype so navigation reads
        // chronologically (past on the left, predictive on the right).
        branches: [
          // 0 — Home (formerly Garden)
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (c, s) => const GardenScreen()),
            ],
          ),
          // 1 — History
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
          // 2 — Log mood (centre, highlighted)
          //
          // Optional `?edit=<entryId>` puts the screen into edit mode:
          // the controller hydrates from the existing entry, the
          // header reads "Edit entry", and Save calls `updateExisting`.
          //
          // The `ValueKey('log-mood:<edit>')` is load-bearing: without
          // it, navigating back and forth between `/log-mood` and
          // `/log-mood?edit=X` reuses the same `State` (because
          // `StatefulShellRoute.indexedStack` keeps the branch alive
          // across visits), and `initState`'s hydration never re-runs.
          // Keying by the edit param forces a fresh `State` on every
          // mode swap so the post-frame hydration always fires.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log-mood',
                builder: (c, s) {
                  final editId = s.uri.queryParameters['edit'];
                  return LogMoodScreen(
                    key: ValueKey('log-mood:${editId ?? "new"}'),
                    editEntryId: editId,
                  );
                },
              ),
            ],
          ),
          // 3 — Patterns / Analytics
          //
          // `/analytics` is the read-mode "Patterns" dashboard. The
          // (S5) `/insights` sub-route is a deeper read with the
          // Pattern-Engine output (mood score time-series + tier
          // markers) gated behind the bipolar / medical disclaimer ack
          // dialog (spec §4, TC-36 / TC-37). It nests under the
          // Patterns branch so the bottom-nav highlight stays on the
          // Patterns tab while the user reads insights.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (c, s) => const AnalyticsScreen(),
                routes: [
                  GoRoute(
                    path: 'insights',
                    name: 'insights',
                    builder: (c, s) => const InsightsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 4 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Phone vs tablet vs desktop breakpoints. Below `tabletMin` we render
  /// the prototype's phone shell verbatim (bottom nav, edge-to-edge page).
  /// At `tabletMin..desktopMin` we keep the bottom nav but add comfortable
  /// horizontal padding around a centred content column. At `desktopMin`
  /// and above we switch to a 240 dp sidebar + flexible body that fills the
  /// remaining width up to a generous reading cap.
  static const double _tabletMin = 600;
  static const double _desktopMin = 900;

  /// Reading cap on very wide displays. A 22 sp paragraph stretched across
  /// 2000 dp is unreadable; capping at 1280 keeps the chart cards a sane
  /// width while still letting Garden / History breathe on a 1440+ monitor.
  static const double _desktopBodyMax = 1280;

  /// Tablets get a tighter content column so cards don't grow to half a
  /// metre wide. ~840 mirrors common tablet "reader" widths.
  static const double _tabletBodyMax = 840;

  /// 5 nav items, in the same order as the [StatefulShellRoute.indexedStack]
  /// branches above. Index here MUST match index there. Material icons
  /// replace the prototype's emoji glyphs so the result is consistent across
  /// platforms.
  static const List<MbBottomNavItem> _items = [
    MbBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
    MbBottomNavItem(icon: Icons.menu_book_outlined, label: 'History'),
    // The middle slot. `highlighted: true` paints it as a primary-tinted
    // circular button so first-time users see the main action immediately.
    MbBottomNavItem(icon: Icons.add, label: 'Add', highlighted: true),
    MbBottomNavItem(icon: Icons.insights_outlined, label: 'Patterns'),
    MbBottomNavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  /// Tapping any nav item always resets that branch to its initial route —
  /// so the user never lands mid-stack on a tab they didn't expect to be
  /// in. Combined with `StatefulShellRoute.indexedStack` keeping the
  /// branch's State alive, this means scroll position resets to top on
  /// every tap (the route rebuilds), which is what the "nav always lands
  /// on top of the page" feedback boils down to. v1.5 polish fix.
  void _goBranch(int i) {
    navigationShell.goBranch(i, initialLocation: true);
  }

  /// Index to highlight in the nav. Normally just `currentIndex`, but
  /// when the user is on `/log-mood?edit=<id>` we return -1 so neither
  /// the bottom-nav Add button nor the desktop sidebar shows an active
  /// state — editing an entry is a transient sub-flow, not a tab.
  int _activeNavIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri;
    final isEditingMood =
        loc.path == '/log-mood' && loc.queryParameters.containsKey('edit');
    if (isEditingMood) return -1;
    return navigationShell.currentIndex;
  }

  /// Body builder. The previous build wrapped the navigation shell in a
  /// 220 ms `TweenAnimationBuilder` fade, but that introduced a visible
  /// stutter on every tab swap (Flutter rebuilds the whole shell once the
  /// branch index changes, then animates opacity over the new tree — on
  /// debug builds especially the first frame lands a few hundred ms
  /// late). Removing the wrapper makes tab swaps feel instantaneous.
  Widget _body() => navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= _desktopMin) return _buildDesktop(context, ref, w);
        if (w >= _tabletMin) return _buildTablet(context);
        return _buildPhone(context);
      },
    );
  }

  /// Sidebar + flexible body. The body fills the remaining width up to
  /// `_desktopBodyMax`, with internal horizontal padding that scales from
  /// 24 dp at narrow desktop widths to 48 dp at wide ones. This is the
  /// layout the user reported as "wasting space" — fixing the previous
  /// hard 900 dp cap is the whole point of this method.
  Widget _buildDesktop(
    BuildContext context,
    WidgetRef ref,
    double availableWidth,
  ) {
    final bodyAvailable = availableWidth - kMbSideNavWidth;
    final hPadding = bodyAvailable < 1100
        ? 24.0
        : bodyAvailable < 1400
        ? 32.0
        : 48.0;

    final themePref = ref.watch(themeModeControllerProvider);

    return Scaffold(
      body: Row(
        children: [
          MbSideNav(
            currentIndex: _activeNavIndex(context),
            onTap: _goBranch,
            items: _items,
            actions: [
              MbSideNavAction(
                icon: _iconForThemePref(themePref),
                label: _labelForThemePref(themePref),
                onTap: () => _showThemeDialog(context, ref, themePref),
                trailing: const Icon(
                  Icons.unfold_more,
                  size: 14,
                  color: Color(0x66808080),
                ),
              ),
              MbSideNavAction(
                icon: Icons.logout,
                label: 'Sign out',
                destructive: true,
                onTap: () => _confirmSidebarSignOut(context, ref),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _desktopBodyMax),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: _body(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForThemePref(ThemeModePreference p) => switch (p) {
    ThemeModePreference.light => Icons.light_mode_outlined,
    ThemeModePreference.dark => Icons.dark_mode_outlined,
    ThemeModePreference.system => Icons.brightness_auto_outlined,
    ThemeModePreference.followDeviceTime => Icons.schedule_outlined,
  };

  static String _labelForThemePref(ThemeModePreference p) => switch (p) {
    ThemeModePreference.light => 'Theme: Light',
    ThemeModePreference.dark => 'Theme: Dark',
    ThemeModePreference.system => 'Theme: Auto (device)',
    ThemeModePreference.followDeviceTime => 'Theme: Auto (time)',
  };

  Future<void> _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeModePreference current,
  ) async {
    final picked = await showDialog<ThemeModePreference>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          for (final option in ThemeModePreference.values)
            RadioListTile<ThemeModePreference>(
              title: Text(_labelForThemePref(option)),
              value: option,
              // ignore: deprecated_member_use
              groupValue: current,
              // ignore: deprecated_member_use
              onChanged: (v) => Navigator.of(dialogContext).pop(v),
            ),
        ],
      ),
    );
    if (picked != null && picked != current) {
      await ref
          .read(themeModeControllerProvider.notifier)
          .setPreference(picked);
    }
  }

  Future<void> _confirmSidebarSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your moods stay safe on this device and in the cloud. You can '
          'always sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA63B2E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(signOutUseCaseProvider)();
  }

  /// Tablet: phone shell (bottom nav) but content column centred at a
  /// comfortable reading width. Avoids the "single 22 sp paragraph spread
  /// across 1024 dp" problem on iPad-class displays.
  Widget _buildTablet(BuildContext context) =>
      _buildPhoneOrTablet(context, contentMaxWidth: _tabletBodyMax);

  /// Phone: edge-to-edge content under the bottom nav.
  Widget _buildPhone(BuildContext context) =>
      _buildPhoneOrTablet(context, contentMaxWidth: double.infinity);

  Widget _buildPhoneOrTablet(
    BuildContext context, {
    required double contentMaxWidth,
  }) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    // Add bottom padding to the body so content isn't hidden under the
    // translucent nav. The nav itself draws its own SafeArea on top of
    // this. The extra 16 dp of breathing room sits between the last
    // scroll-end card and the nav's translucent edge — without it,
    // primary buttons (e.g. Save) ended up flush against the nav.
    const navBreathingRoom = 16.0;
    final bodyBottomPad = kMbBottomNavHeight + bottomSafe + navBreathingRoom;

    return Scaffold(
      // Stack lets the translucent + blurred nav layer over the body so the
      // BackdropFilter has actual pixels to blur. Bottom-nav slot would clip
      // those pixels away.
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bodyBottomPad),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: _body(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MbBottomNav(
              currentIndex: _activeNavIndex(context),
              onTap: _goBranch,
              items: _items,
            ),
          ),
        ],
      ),
    );
  }
}

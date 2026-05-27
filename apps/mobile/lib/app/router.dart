import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/analytics/presentation/analytics_screen.dart';

import '../features/auth/data/providers.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/privacy_lock_screen.dart';
import '../features/auth/presentation/screens/privacy_setup_flow_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/garden/presentation/garden_screen.dart';
import '../features/history/presentation/entry_detail_screen.dart'
    show EntryDetailSheet;
import '../features/history/presentation/history_screen.dart';
import '../features/intervention/domain/entities/intervention_dispatch.dart';
import '../features/intervention/presentation/screens/breathing_screen.dart';
import '../features/intervention/presentation/screens/crisis_resources_screen.dart';
import '../features/intervention/presentation/screens/journaling_prompt_screen.dart';
import '../features/mood/data/providers.dart' as mood_providers;
import '../features/mood/presentation/controllers/log_mood_controller.dart'
    show logMoodControllerProvider;
import '../features/mood/presentation/log_mood_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/domain/entities/theme_mode_preference.dart';
import '../features/settings/presentation/controllers/theme_mode_controller.dart';
import '../features/tokens/presentation/screens/skin_shop_screen.dart';
import 'widgets/mb_bottom_nav.dart';
import 'widgets/mb_side_nav.dart';

// Route swaps render instantly to reduce perceived lag.
NoTransitionPage<void> _noTransition(Widget child) =>
    NoTransitionPage<void>(child: child);

/// Transparent route page that hosts a [_ModalLauncher]. `opaque: false`
/// lets the branch content below show through the modal's scrim so a
/// deep-linked modal (e.g. notification → breathing) appears over the
/// real shell rather than a blank page. Uses [CustomTransitionPage]
/// because `NoTransitionPage` is always opaque.
CustomTransitionPage<void> _modalLauncherPage(
  Future<void> Function(BuildContext) open,
) => CustomTransitionPage<void>(
  opaque: false,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
  child: _ModalLauncher(open: open),
);

/// Opens a modal once after the first frame, then pops its own route
/// when the modal is dismissed. Used to make `pushNamed` / deep-linked
/// routes resolve to a modal surface while keeping the navigation
/// contract (route name + extra) unchanged.
class _ModalLauncher extends StatefulWidget {
  const _ModalLauncher({required this.open});

  final Future<void> Function(BuildContext) open;

  @override
  State<_ModalLauncher> createState() => _ModalLauncherState();
}

class _ModalLauncherState extends State<_ModalLauncher> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_opened || !mounted) return;
      _opened = true;
      await widget.open(context);
      if (!mounted) return;
      if (context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

/// Per-branch scroll controller, keyed by `StatefulShellBranch` index
/// (0 = Home, 1 = History, 2 = Log, 3 = Patterns, 4 = Settings).
///
/// Each branch's top-level screen wraps itself in a
/// `PrimaryScrollController` reading the matching controller from this
/// provider, so the screen's scroll view (`primary: true` by default)
/// attaches to a controller that's bound to THAT branch — never shared
/// with sibling branches. A single shell-wide controller would not work:
/// `StatefulShellRoute.indexedStack` keeps every branch's widget alive,
/// so all five scroll views would re-attach to whichever controller was
/// currently in scope and clobber each other's positions.
final branchScrollControllerProvider = Provider.family<ScrollController, int>((
  ref,
  _,
) {
  final c = ScrollController();
  ref.onDispose(c.dispose);
  return c;
});

Widget _branchScope(ScrollController controller, Widget child) =>
    PrimaryScrollController(controller: controller, child: child);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AppUser?>(null);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AppUser?>>(currentUserStreamProvider, (previous, next) {
    refresh.value = next.value;

    final prevUid = previous?.value?.uid;
    final nextUid = next.value?.uid;

    // Drive the MoodSyncManager lifecycle off auth-state transitions.
    // Sign-in (or auth resolves with a non-null user on app start) → bootstrap
    // the sync manager so Drift is seeded once per uid and the live listener
    // attaches. Sign-out → shutdown so the previous user's listener and timers
    // are torn down before another sign-in re-attaches.
    //
    // Skipped on Web: Drift's native connector is unavailable there. The
    // repository's offlineFirstEnabledProvider already defaults to
    // `!kIsWeb`, so reads/writes route through Firestore directly;
    // bootstrapping the sync manager would only open a DB that throws on
    // first query.
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

    // On sign-out (non-null → null), clear the session-scoped Privacy
    // Lock unlock flag so a future re-sign-in re-prompts. Correct
    // security behaviour: a fresh login should re-verify on cold boot.
    if (previous?.value != null && next.value == null) {
      ref.read(privacyLockUnlockedThisSessionProvider.notifier).state = false;
    }
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(_onboardingCompleteKey) ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/sign-in' || loc == '/sign-up' || loc == '/forgot-password';

      if (!onboardingDone && loc != '/onboarding') return '/onboarding';
      if (onboardingDone && loc == '/onboarding') {
        return refresh.value == null ? '/sign-in' : '/home';
      }
      if (onboardingDone && refresh.value == null && !isAuthRoute) {
        return '/sign-in';
      }
      if (refresh.value != null && isAuthRoute) return '/home';

      // Privacy Lock gate — whole-app cold-boot scope. Inserts itself
      // when (a) the user is signed in, (b) the user has opted into
      // Privacy Lock, and (c) we haven't already unlocked this session.
      //
      // `privacyLockEnabledProvider` is pre-resolved in main.dart via
      // `SeededPrivacyLockEnabledNotifier`, so this read returns a real
      // bool on the very first redirect pass — no FutureProvider race,
      // no flash-of-home. The `/privacy/setup` modal route is exempt so
      // toggling ON from Settings doesn't fire the lock mid-setup; the
      // unlock screen itself short-circuits the redirect.
      final isUnlockRoute = loc == '/privacy-lock';
      final isPrivacySetup = loc == '/privacy/setup';
      if (refresh.value != null &&
          !isUnlockRoute &&
          !isPrivacySetup &&
          ref.read(privacyLockEnabledProvider) &&
          !ref.read(privacyLockUnlockedThisSessionProvider)) {
        // Thread the original destination through as `returnTo` so the
        // user lands where they were navigating instead of being
        // dumped on `/home` after unlock. The cold-boot path
        // (loc == '/home') passes `/home` and is a no-op.
        final returnTo = Uri.encodeComponent(loc);
        return '/privacy-lock?returnTo=$returnTo';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (c, s) => _noTransition(const OnboardingScreen()),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (c, s) => _noTransition(const SignInScreen()),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (c, s) => _noTransition(const SignUpScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (c, s) => _noTransition(const ForgotPasswordScreen()),
      ),
      // Unified Privacy Lock unlock screen — biometric (when available)
      // + PIN fallback. Reachable via the cold-boot redirect above when
      // the user has opted in. `returnTo` is URL-encoded by the redirect
      // so any deep-link destination survives the round-trip.
      GoRoute(
        path: '/privacy-lock',
        pageBuilder: (c, s) {
          final returnTo = s.uri.queryParameters['returnTo'];
          return _noTransition(PrivacyLockScreen(returnTo: returnTo));
        },
      ),
      // First-time setup flow for Privacy Lock. Modal route reached via
      // Settings → PRIVACY → "Privacy Lock" switch ON. Pops with `true`
      // on success and `false` on cancellation. Exempt from the
      // cold-boot gate so toggling ON doesn't fire the lock mid-setup.
      GoRoute(
        path: '/privacy/setup',
        pageBuilder: (c, s) => _noTransition(const PrivacySetupFlowScreen()),
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
          // Intervention surfaces nest under /home so the shell (bottom
          // nav on phone, sidebar on desktop) stays visible while the
          // user breathes / journals / reads crisis resources. Named
          // routes are preserved so the InterventionBanner's
          // pushNamed('intervention.breathing', extra: dispatch) keeps
          // working — only the URL surface changes.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (c, s) => _noTransition(
                  _branchScope(
                    ref.read(branchScrollControllerProvider(0)),
                    const GardenScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'intervention/breathing',
                    name: 'intervention.breathing',
                    pageBuilder: (c, s) {
                      final dispatch = s.extra is InterventionDispatch
                          ? s.extra as InterventionDispatch
                          : null;
                      // Present the breathing exercise as a modal over
                      // the shell. The launcher pops this route when the
                      // sheet is dismissed.
                      return _modalLauncherPage(
                        (ctx) => BreathingSheet.show(ctx, dispatch: dispatch),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'intervention/journal',
                    name: 'intervention.journal',
                    pageBuilder: (c, s) {
                      final dispatch = s.extra is InterventionDispatch
                          ? s.extra as InterventionDispatch
                          : null;
                      return _noTransition(
                        JournalingPromptScreen(dispatch: dispatch),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'intervention/crisis',
                    name: 'intervention.crisis',
                    pageBuilder: (c, s) {
                      final dispatch = s.extra is InterventionDispatch
                          ? s.extra as InterventionDispatch
                          : null;
                      return _noTransition(
                        CrisisResourcesScreen(dispatch: dispatch),
                      );
                    },
                  ),
                ],
              ),
              // Skin Shop. Nested under /home so the shell nav (bottom
              // nav on phone, sidebar on desktop) stays visible while
              // the user browses skins. Reachable from (a) the
              // "Customize" pill in the SkyHeader top-right, and
              // (b) the GARDEN -> "Customize your garden" Settings tile.
              GoRoute(
                path: '/garden/skins',
                pageBuilder: (c, s) => _noTransition(const SkinShopScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (c, s) => _noTransition(
                  _branchScope(
                    ref.read(branchScrollControllerProvider(1)),
                    const HistoryScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    // Entry detail is a modal now. A deep link to
                    // /history/<id> lands on the History list with the
                    // entry-detail sheet opened over it; dismissing the
                    // sheet pops this launcher route back to the list.
                    pageBuilder: (c, s) {
                      final id = s.pathParameters['id'] ?? '';
                      return _modalLauncherPage(
                        (ctx) => EntryDetailSheet.show(ctx, id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Log mood (centre, highlighted).
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
                pageBuilder: (c, s) {
                  final editId = s.uri.queryParameters['edit'];
                  return _noTransition(
                    _branchScope(
                      ref.read(branchScrollControllerProvider(2)),
                      LogMoodScreen(
                        key: ValueKey('log-mood:${editId ?? "new"}'),
                        editEntryId: editId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          // Patterns. Single screen since v1.5.1 — the former
          // `/analytics/insights` sub-route was folded into the dashboard
          // with the bipolar/medical disclaimer rendered as an inline
          // banner instead of a route-level modal gate.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (c, s) => _noTransition(
                  _branchScope(
                    ref.read(branchScrollControllerProvider(3)),
                    const AnalyticsScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (c, s) => _noTransition(
                  _branchScope(
                    ref.read(branchScrollControllerProvider(4)),
                    const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Phone vs tablet vs desktop breakpoints. Below `MbBreakpoints.phone`
  /// we render the prototype's phone shell verbatim (bottom nav,
  /// edge-to-edge page). At `phone..desktop` we keep the bottom nav but
  /// add comfortable horizontal padding around a centred content column.
  /// At `MbBreakpoints.desktop` and above we switch to a 240 dp sidebar
  /// + flexible body that fills the remaining width up to a generous
  /// reading cap.
  static const double _tabletMin = MbBreakpoints.phone;
  static const double _desktopMin = MbBreakpoints.desktop;

  /// Reading cap on very wide displays. A 22 sp paragraph stretched across
  /// 2000 dp is unreadable; capping at 1280 keeps the chart cards a sane
  /// width while still letting Garden / History breathe on a 1440+ monitor.
  static const double _desktopBodyMax = 1280;

  /// Tablets get a tighter content column so cards don't grow to half a
  /// metre wide. ~720 mirrors the prototype's tablet artboard reading
  /// width — the same value used by `MbBreakpoints.homeWide` so the
  /// shell cap and the screen-internal "go wide" cutover coincide.
  static const double _tabletBodyMax = MbBreakpoints.homeWide;

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

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _goBranch(int i) {
    final isSameBranch = navigationShell.currentIndex == i;
    navigationShell.goBranch(i, initialLocation: true);
    // Tapping a nav item starts that branch fresh: clear any
    // in-progress mood draft (mood selection, intensity, note, AI
    // suggestion) so returning to "Add" never resurfaces a stale
    // half-filled form. Cheap + idempotent when the draft is already
    // empty.
    ref.read(logMoodControllerProvider.notifier).reset();
    // Re-tap or cross-branch tap both reset scroll position to top.
    // Each branch owns its own ScrollController (via
    // `branchScrollControllerProvider`) bound to its own page wrapper,
    // so the destination controller is already attached to the branch's
    // scroll view by the time the next frame builds.
    //
    // The `mounted` guard prevents the
    //   "Using `ref` when a widget is about to or has been unmounted"
    // assertion that fired when the user signed out (or any other path
    // that disposes the AppShell) between this tap and the post-frame
    // callback. Without it, the scheduler-scoped throw broke onto the
    // console and surfaced the red overlay.
    void doJump() {
      if (!mounted) return;
      final c = ref.read(branchScrollControllerProvider(i));
      if (c.hasClients) c.jumpTo(0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doJump();
      // Cross-branch taps need a second post-frame: when the previously
      // inactive branch's IndexedStack child becomes visible, its scroll
      // view may take one extra frame to attach to the controller.
      if (!isSameBranch) {
        WidgetsBinding.instance.addPostFrameCallback((_) => doJump());
      }
    });
  }

  int _activeNavIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri;
    final isEditingMood =
        loc.path == '/log-mood' && loc.queryParameters.containsKey('edit');
    if (isEditingMood) return -1;
    return navigationShell.currentIndex;
  }

  Widget _body() => navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= _AppShell._desktopMin) return _buildDesktop(context, ref, w);
        if (w >= _AppShell._tabletMin) return _buildTablet(context);
        return _buildPhone(context);
      },
    );
  }

  /// Sidebar + flexible body. The body fills the remaining width up to
  /// `_desktopBodyMax`, with internal horizontal padding that scales from
  /// 24 dp at narrow desktop widths to 48 dp at wide ones.
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
            items: _AppShell._items,
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
                constraints: const BoxConstraints(
                  maxWidth: _AppShell._desktopBodyMax,
                ),
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
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
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
      _buildPhoneOrTablet(context, contentMaxWidth: _AppShell._tabletBodyMax);

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
              items: _AppShell._items,
            ),
          ),
        ],
      ),
    );
  }
}

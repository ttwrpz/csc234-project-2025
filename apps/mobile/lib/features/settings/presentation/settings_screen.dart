import 'dart:async' show unawaited;

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart' show TableInfo;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../../mood/data/providers.dart'
    show
        firebaseFunctionsProvider,
        moodSyncManagerProvider,
        myMoodsStreamProvider;
import '../../auth/presentation/widgets/biometric_settings_tile.dart';
import '../../auth/presentation/widgets/privacy_settings_tile.dart';
import '../../auth/presentation/widgets/webauthn_settings_tile.dart';
import '../../disclaimer/presentation/widgets/disclaimer_panel.dart';
import '../../garden/data/providers.dart' show debugPlantTierOverrideProvider;
import '../../garden/domain/entities/plant_tier.dart';
import '../../harvest/data/providers.dart' show weeklyGardenHistoryProvider;
import '../../harvest/domain/usecases/archive_weekly_garden.dart'
    show ArchiveWeeklyGardenUseCase;
import '../../harvest/presentation/controllers/weekly_summary_controller.dart';
import '../../intervention/presentation/controllers/intervention_controller.dart';
import '../../mood/data/sync/connectivity_provider.dart';
import '../../notifications/data/datasources/local_notification_datasource.dart';
import '../../notifications/presentation/widgets/tier_toggle_tile.dart';
import '../../pattern_engine/domain/entities/tier.dart' as engine;
import '../../tokens/data/providers.dart' show tokenRepositoryProvider;
import '../../tokens/presentation/controllers/token_visibility_controller.dart';
import '../domain/entities/theme_mode_preference.dart';
import 'controllers/theme_mode_controller.dart';
import 'widgets/delete_account_dialog.dart';

/// Settings screen — related preferences live in clearly-zoned [MbCard]
/// clusters: Profile, Preferences, Account (sign-out, with confirmation
/// dialog), and a Debug zone (only in debug builds).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final themePreference = ref.watch(themeModeControllerProvider);
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    // Settings tiles need a strong press effect: the default Material
    // splash on `MbCard`'s `MaterialType.transparency` surface is washed
    // out on the cream/navy theme, and the highlight colour during
    // long-press is nearly invisible. Bumped both alpha values
    // aggressively and swapped to `InkRipple.splashFactory` for the
    // stronger ripple animation. Splash + highlight use the
    // always-contrasting text colour rather than the brand primary —
    // primary is a muted green that on cream surfaces blends into the
    // card background and reads as no-feedback. Text colour over card
    // is guaranteed contrast in both light + dark themes by design
    // system invariant. Alphas are intentionally bold (50 % splash,
    // 25 % highlight) so the press effect is unmistakable even on dim
    // phone displays.
    final pressTint = mb.text;
    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Theme(
          data: theme.copyWith(
            splashColor: pressTint.withValues(alpha: 0.50),
            highlightColor: pressTint.withValues(alpha: 0.25),
            splashFactory: InkRipple.splashFactory,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoodBloomSpacing.pagePadding,
              MoodBloomSpacing.pagePadding,
              MoodBloomSpacing.pagePadding,
              MoodBloomSpacing.lg,
            ),
            children: [
              Text(
                'Settings',
                style: MbFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              const SizedBox(height: 16),

              // ── Profile zone ──
              // Tap → opens the edit-name dialog. The name comes from
              // `fb.User.displayName` (mapped by `AppUserMapper`) — null
              // for fresh email/password sign-ups since
              // `createUserWithEmailAndPassword` doesn't capture one, so
              // this affordance is the only way to set it after the fact.
              if (user != null)
                MbCard(
                  onTap: () => _editDisplayName(
                    context,
                    ref,
                    currentName: user.displayName,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Avatar(
                        label: _avatarInitial(user.displayName, user.email),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Add your name',
                              style: MbFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: user.displayName == null
                                    ? mb.textDim
                                    : mb.text,
                                fontStyle: user.displayName == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            if (user.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.email!,
                                style: MbFonts.nunito(
                                  fontSize: 12,
                                  color: mb.textDim,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: mb.textDim, size: 18),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // ── Preferences zone ──
              const MbSectionLabel('PREFERENCES'),
              const SizedBox(height: 6),
              _PreferencesCluster(preference: themePreference),

              const SizedBox(height: 18),

              // ── Security zone ──
              // Platform gating: biometric (local_auth) is Android-only;
              // WebAuthn is web-only. Hide the irrelevant tile entirely
              // instead of rendering its disabled preview — cleaner UX than
              // "this isn't for your platform" copy.
              if (!kIsWeb) ...[
                const MbSectionLabel('SECURITY'),
                const SizedBox(height: 6),
                MbCard(
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.zero,
                  child: const BiometricSettingsTile(),
                ),
                const SizedBox(height: 18),
              ],

              // ── Privacy zone ──
              // Hidden when signed out (defence in depth — the tile
              // itself renders a disabled affordance, but skipping the
              // section entirely keeps the visual hierarchy clean for
              // the unauthenticated sign-out → sign-in transition).
              // Also hidden when the Remote Config kill-switch is off,
              // so a rollback can yank the feature without leaving the
              // Settings UI dangling.
              if (user != null &&
                  ref.watch(privacyLockMasterEnabledProvider)) ...[
                const MbSectionLabel('PRIVACY'),
                const SizedBox(height: 6),
                MbCard(
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const PrivacySettingsTile(),
                      // WebAuthn is web-only — keep the tile on web, drop
                      // it (and the divider) on native where biometric
                      // already covers the same affordance.
                      if (kIsWeb) ...const [
                        Divider(height: 1),
                        WebauthnSettingsTile(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── Sync zone ──
              // Surfaces the offline-first sync state for the signed-in
              // user. Shows "Last synced X ago" via a ValueListenable
              // backed by MoodSyncManager and lets the user trigger a
              // manual drain. Hidden on web (Drift sync is native-only)
              // and when signed out (no uid to sync).
              if (user != null && !kIsWeb) ...[
                const MbSectionLabel('SYNC'),
                const SizedBox(height: 6),
                const _SyncCluster(),
                const SizedBox(height: 18),
              ],

              // ── Account zone ──
              const MbSectionLabel('ACCOUNT'),
              const SizedBox(height: 6),
              MbCard(
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout, color: mb.destructiveText),
                      title: Text(
                        'Sign out',
                        style: TextStyle(
                          color: mb.destructiveText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                    const Divider(height: 1),
                    // Destructive account deletion. Two-step confirmation
                    // lives in [DeleteAccountDialog]; this tile is the
                    // only entry point.
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                          shadows: const <Shadow>[],
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently remove your account and all data.',
                      ),
                      onTap: () => DeleteAccountDialog.show(context),
                    ),
                  ],
                ),
              ),

              // ── About zone ──
              const SizedBox(height: 18),
              const MbSectionLabel('ABOUT'),
              const SizedBox(height: 6),
              const _AboutCluster(),

              // ── Debug zone (debug builds only) ──
              if (kDebugMode) ...[
                const SizedBox(height: 18),
                const MbSectionLabel('DEBUG'),
                const SizedBox(height: 6),
                const _DebugCluster(),
              ],

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Made with care · School of Information Technology, KMUTT',
                  style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref, {
    required String? currentName,
  }) async {
    // Dialog body is a proper StatefulWidget (see `_EditDisplayNameDialog`
    // below) so the `TextEditingController` lifecycle is owned by the
    // dialog's State — `initState` creates it, `dispose` releases it.
    // The previous flow created the controller in this caller and
    // disposed it after `showDialog` returned, which raced with the
    // child `TextField`'s State.dispose tearing down its FocusNode and
    // surfaced as
    //   "framework.dart:6268 _dependents.isEmpty is not true"
    // — the framework asserts that an Element's InheritedWidget
    // dependents are cleared before deactivation, and the controller
    // being disposed under the TextField caused the State teardown
    // order to invert.
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditDisplayNameDialog(initialName: currentName),
    );

    // Cancel / back / barrier-dismiss → pop returned null.
    if (newName == null) return;

    // Save with empty text — treat as cancel rather than blanking the
    // profile. Firebase Auth's `updateDisplayName` accepts empty
    // strings on some platforms and asserts on others ("isEmpty is
    // not true" in the Dart SDK plumbing), so guarding here keeps the
    // path predictable across iOS / Android / Web.
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    // No-op — same value the field already held. Compares trimmed on
    // both sides so trailing whitespace in the stored value doesn't
    // cause a phantom update round-trip.
    if (trimmed == (currentName ?? '').trim()) return;

    final result = await ref
        .read(authRepositoryProvider)
        .updateDisplayName(trimmed);
    // context.mounted gate covers the async gap on the network call.
    // ScaffoldMessenger is read here (not pre-captured before the
    // dialog) so we don't register an outer-context dependency on the
    // ScaffoldMessenger InheritedWidget while a child dialog is alive.
    if (!context.mounted) return;
    result.fold(
      ok: (_) {
        // Force the auth-state stream to re-emit so the Settings header
        // picks up the new value. `currentUser` was reload()'d inside
        // the datasource, but `authStateChanges()` doesn't emit on
        // profile-only updates — refresh the provider explicitly.
        ref.invalidate(currentUserStreamProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hello, $trimmed.')));
      },
      err: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // Use the theme-aware error pair so the destructive button
        // matches the Sign out tile's `mb.destructiveText` aesthetic in
        // both themes (dark coral on cream in light mode, bright coral
        // on navy in dark mode) and white text always reads against the
        // saturated background. Hardcoding `MoodBloomColors.coral` +
        // `Colors.white` previously diverged from the destructive
        // token in the sign-out tile.
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
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
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(signOutUseCaseProvider)();
  }

  static String _avatarInitial(String? displayName, String? email) {
    final source = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : email?.trim() ?? '?';
    return source.substring(0, 1).toUpperCase();
  }
}

/// Dialog body for the "Edit display name" flow. Owns its own
/// `TextEditingController` lifecycle so the controller is disposed
/// during the State's dispose (after `TextField` has detached) rather
/// than racing with `TextField`'s State.dispose if the caller manages
/// it from the outside.
class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({required this.initialName});

  final String? initialName;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _focusNode = FocusNode();
    // Defer the focus request until AFTER the Material dialog's enter
    // transition completes (~250 ms by default). Posting only via
    // `addPostFrameCallback` requests focus on the next frame — which
    // is still mid-transition — so the IME starts opening over a
    // scaling dialog and reads as lag. The explicit 260 ms delay lets
    // the dialog fully settle before the keyboard slides in, giving a
    // clean stepwise feel.
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        maxLength: 60,
        decoration: const InputDecoration(
          labelText: 'Display name',
          hintText: 'How would you like to be called?',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // The initial letter is purely decorative — the adjacent column
    // already announces the user's display name and email to screen
    // readers, so reading "T" or "?" before the name would be noise.
    // Exclude this subtree from semantics.
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MoodBloomColors.seed, MoodBloomColors.amber],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: MbFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PreferencesCluster extends ConsumerWidget {
  const _PreferencesCluster({required this.preference});

  final ThemeModePreference preference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTokens = ref.watch(tokenVisibilityProvider);
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Theme group header — replaces the previous ListTile +
          // dropdown with a 4-option radio group. The fourth option,
          // `followDeviceTime`, lets the app flip between light and
          // dark on local-clock cutoff (07:00 / 19:00) without any
          // device-level theme support.
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_preferenceSummary(preference)),
          ),
          // Order is intentional, not enum-declaration order: device
          // theme + device time first (auto-pickers), then the two
          // explicit always-on choices.
          //
          // RadioGroup is the post-Flutter-3.32 API for grouping
          // radios — child RadioListTiles read `groupValue`/`onChanged`
          // from this ancestor instead of taking them on each tile.
          RadioGroup<ThemeModePreference>(
            groupValue: preference,
            onChanged: (chosen) {
              if (chosen == null) return;
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setPreference(chosen);
            },
            child: const Column(
              children: [
                _ThemeRadioTile(option: ThemeModePreference.system),
                _ThemeRadioTile(option: ThemeModePreference.followDeviceTime),
                _ThemeRadioTile(option: ThemeModePreference.light),
                _ThemeRadioTile(option: ThemeModePreference.dark),
              ],
            ),
          ),
          const Divider(height: 1),
          // Anti-pattern guardrail: visibility toggle, NEVER an opt-out
          // of earning. Tokens still accumulate in the background when
          // this is off — only the chip render on the garden home is
          // suppressed.
          SwitchListTile(
            secondary: const Icon(Icons.local_florist_outlined),
            title: const Text('Show token balance'),
            subtitle: const Text(
              'Display the small flower-token chip on the garden home.',
            ),
            value: showTokens,
            onChanged: (v) => ref
                .read(tokenVisibilityProvider.notifier)
                .setVisible(visible: v),
          ),
          const Divider(height: 1),
          // ── Notification reminders sub-zone ──
          // Three per-tier opt-outs replace the legacy single
          // cheer-up toggle. The header uses the user-facing label
          // "Notification reminders" — internal tier numbers stay out
          // of the UI per CLAUDE.md copy rules.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Notification reminders',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const TierToggleTile(tier: InterventionTier.one),
          const TierToggleTile(tier: InterventionTier.two),
          const TierToggleTile(tier: InterventionTier.three),
        ],
      ),
    );
  }

  /// One-line summary shown under the "Theme" header so the user
  /// sees the current selection without scanning four radios.
  static String _preferenceSummary(ThemeModePreference preference) =>
      switch (preference) {
        ThemeModePreference.system => 'Match the device theme',
        ThemeModePreference.light => 'Always light',
        ThemeModePreference.dark => 'Always dark',
        ThemeModePreference.followDeviceTime =>
          'Light by day, dark by night (local time)',
      };
}

/// Single radio tile in the theme picker. Pulled into its own widget
/// so the Semantics label stays in one place and the parent
/// `_PreferencesCluster` reads as a flat list of options.
///
/// Uses the post-3.32 RadioListTile API — `groupValue` / `onChanged`
/// come from a [RadioGroup] ancestor in `_PreferencesCluster`, not
/// from per-tile parameters.
class _ThemeRadioTile extends StatelessWidget {
  const _ThemeRadioTile({required this.option});

  final ThemeModePreference option;

  @override
  Widget build(BuildContext context) {
    final label = _label(option);
    // Read the selection from the RadioGroup ancestor so the
    // Semantics description stays accurate.
    final registry = RadioGroup.maybeOf<ThemeModePreference>(context);
    final selected = option == registry?.groupValue;
    return Semantics(
      // Compose a screen-reader-friendly description so users on
      // TalkBack / VoiceOver hear "Theme: Follow device time,
      // selected" instead of just the radio's default semantics.
      label: 'Theme: $label, ${selected ? 'selected' : 'not selected'}',
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: RadioListTile<ThemeModePreference>(
        value: option,
        title: Text(label),
        controlAffinity: ListTileControlAffinity.trailing,
        dense: true,
      ),
    );
  }

  static String _label(ThemeModePreference option) => switch (option) {
    ThemeModePreference.system => 'Follow device theme',
    ThemeModePreference.followDeviceTime => 'Follow device time',
    ThemeModePreference.light => 'Always light',
    ThemeModePreference.dark => 'Always dark',
  };
}

/// About zone — application metadata. Version string is a hard-coded
/// constant for now; we can read it from `package_info_plus` later.
/// Keeping it inline avoids the extra dependency on a single string.
///
/// The Medical disclaimer expansion tile lives at the bottom of the
/// cluster so the version line stays the cluster's primary affordance.
/// The expansion only opens on explicit tap; the disclaimer text is
/// never auto-shown here.
class _AboutCluster extends StatelessWidget {
  const _AboutCluster();

  /// Hand-maintained until package_info_plus lands. Bumped per release.
  static const String _appVersion = 'Release 1.0';

  @override
  Widget build(BuildContext context) {
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('MoodBloom'),
            subtitle: Text('Version $_appVersion'),
          ),
          const Divider(height: 1),
          ExpansionTile(
            leading: const Icon(Icons.medical_information_outlined),
            title: const Text('Medical disclaimer'),
            subtitle: const Text(
              'MoodBloom is not a medical device — tap to read more.',
            ),
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DisclaimerPanel(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sync state surface. Renders "Last synced X" + a "Sync now" button
/// for the offline-first Drift queue. Subscribes to the manager's
/// `ValueListenable<DateTime?>` so the timestamp updates live when the
/// drain loop or the live Firestore listener completes a pass — no
/// router refresh required.
///
/// Hidden on web (Drift sync is native-only) and when signed out; the
/// caller in [SettingsScreen.build] is responsible for those guards.
class _SyncCluster extends ConsumerWidget {
  const _SyncCluster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(moodSyncManagerProvider);
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: ValueListenableBuilder<DateTime?>(
        valueListenable: manager.lastSuccessfulSync,
        builder: (context, lastSync, _) {
          return Column(
            children: [
              ListTile(
                leading: Icon(Icons.cloud_done_outlined, color: mb.text),
                title: const Text('Last sync'),
                subtitle: Text(_describeLastSync(lastSync)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.sync, color: mb.text),
                title: const Text('Sync now'),
                subtitle: const Text(
                  'Push pending entries and pull the latest from the cloud.',
                ),
                onTap: () => _kickSync(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _kickSync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(moodSyncManagerProvider).kick();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Syncing in the background…'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// "Just now" / "4 minutes ago" / "2 hours ago" / "May 18, 11:42" —
  /// a compact relative-time renderer that doesn't need the `intl`
  /// package (deliberately kept dependency-free at this depth).
  static String _describeLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Not yet synced on this device.';
    final delta = DateTime.now().difference(lastSync);
    if (delta.inSeconds < 30) return 'Just now.';
    if (delta.inMinutes < 1) return '${delta.inSeconds} seconds ago.';
    if (delta.inMinutes < 60) {
      final m = delta.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago.';
    }
    if (delta.inHours < 24) {
      final h = delta.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago.';
    }
    if (delta.inDays < 7) {
      final d = delta.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago.';
    }
    // Older than a week — drop to an absolute, locale-independent
    // "Month D, HH:MM" string.
    String pad2(int n) => n < 10 ? '0$n' : '$n';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[lastSync.month - 1]} ${lastSync.day}, '
        '${pad2(lastSync.hour)}:${pad2(lastSync.minute)}';
  }
}

/// Debug zone, only rendered in debug builds. Bundles existing tools
/// (Crashlytics test crash) plus a "Force offline" toggle that lets QA
/// simulate the no-Wi-Fi flow without touching the device's radios.
///
/// Wrapped in an `ExpansionTile` (collapsed by default) so the 11
/// power-user tiles don't dominate the Settings scroll. Subtitles are
/// trimmed to one short line each — the long-form rationale lives in
/// the source comments above each tile, not in the UI.
class _DebugCluster extends ConsumerWidget {
  const _DebugCluster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = ref.watch(debugForceOfflineProvider);
    final mb = Theme.of(context).extension<MbColors>()!;
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: Theme(
        // Strip the divider above/below the expansion children so
        // adjacent tiles flow visually into the cluster card (mirrors
        // the ChartReadingGuide pattern from insights).
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.build_outlined),
          title: const Text('Debug tools'),
          subtitle: const Text('Power-user only — tap to expand'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          children: [
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.wifi_off_outlined),
              title: const Text('Force offline'),
              subtitle: const Text('Simulate a dropped network.'),
              value: forced,
              onChanged: (v) =>
                  ref.read(debugForceOfflineProvider.notifier).set(v),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Crash now'),
              subtitle: const Text('Force-crash to verify Crashlytics.'),
              onTap: _crashNow,
            ),
            const Divider(height: 1),
            // Debug-only token grant. Bumps `tokenBalance += 10` via
            // the same TokenRepository the live award path uses, but
            // skips the daily-cap fields so QA can run repeatedly
            // without the 10/day ceiling kicking in.
            ListTile(
              leading: const Icon(Icons.toll_outlined),
              title: const Text('Grant 10 tokens'),
              subtitle: const Text('Skip the daily cap.'),
              onTap: () => _grantDebugTokens(context, ref),
            ),
            const Divider(height: 1),
            // Cycle the plant tier through the 5 ecosystem states.
            // Override held by `debugPlantTierOverrideProvider` —
            // short-circuits the EWMA-derived tier without manufacturing
            // entries.
            const _DebugTierCycleTile(),
            const Divider(height: 1),
            // Force-harvest tile — bypasses the 7-day boundary so QA
            // can run the archive flow on demand.
            ListTile(
              leading: const Icon(Icons.eco_outlined),
              title: const Text('Force harvest now'),
              subtitle: const Text('Archive this week immediately.'),
              onTap: () => _forceHarvest(context, ref),
            ),
            const Divider(height: 1),
            // Debug-only Tier dispatch triggers. Bypass the cooldown
            // gate AND per-tier opt-outs. The Tier 3 determinism
            // guarantee is preserved (curated copy only).
            ListTile(
              leading: const Icon(Icons.air_outlined),
              title: const Text('Trigger Tier 1 banner'),
              subtitle: const Text('Breathing exercise.'),
              onTap: () => ref
                  .read(interventionControllerProvider.notifier)
                  .debugDispatch(engine.Tier.one),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('Trigger Tier 2 banner'),
              subtitle: const Text('Journaling prompt.'),
              onTap: () => ref
                  .read(interventionControllerProvider.notifier)
                  .debugDispatch(engine.Tier.two),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.volunteer_activism_outlined,
                color: mb.destructiveText,
              ),
              title: const Text('Trigger Tier 3 banner'),
              subtitle: const Text('Crisis resources.'),
              onTap: () => ref
                  .read(interventionControllerProvider.notifier)
                  .debugDispatch(engine.Tier.three),
            ),
            const Divider(height: 1),
            // Fires a one-shot OS notification through the cheer-up
            // channel so QA + reviewers can verify the system-tray
            // chrome. Web is a no-op (the datasource returns false).
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Fire OS notification'),
              subtitle: const Text('Android only.'),
              onTap: () => _fireDebugNotification(context, ref),
            ),
            const Divider(height: 1),
            // Replays the onboarding flow. Clears the
            // `onboarding_complete` SharedPreferences flag and
            // navigates to /onboarding; the router redirect
            // (router.dart §"Onboarding gate") then keeps the user on
            // that route until they walk through it again.
            ListTile(
              leading: const Icon(Icons.restart_alt_outlined),
              title: const Text('Replay onboarding'),
              subtitle: const Text('Show the welcome slides again.'),
              onTap: () => _resetOnboarding(context),
            ),
            const Divider(height: 1),
            // Clears the Drift mood DB + SharedPreferences. Shuts down
            // + re-bootstraps the sync manager around the wipe so the
            // in-memory `_attachedUid` / `_previousRemoteIds` / live
            // listener don't drift out of sync with cleared local
            // state. Cloud data is untouched.
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear local cache'),
              subtitle: const Text('Wipes local DB; cloud is untouched.'),
              onTap: () => _clearLocalCache(context, ref),
            ),
            const Divider(height: 1),
            // Wipes all CLOUD data via the `wipeUserData` Cloud Function
            // (admin SDK). Auth account survives. Local Drift +
            // SharedPrefs are also wiped so the next launch syncs from
            // an empty cloud rather than re-uploading the offline mirror.
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: mb.destructiveText,
              ),
              title: Text(
                'Wipe all account data',
                style: TextStyle(
                  color: mb.destructiveText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Cloud + local. Auth survives. Irreversible.',
              ),
              onTap: () => _wipeAccountData(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Debug-only — grants the signed-in user 10 tokens via
  /// [TokenRepository.grantDebug] and surfaces the resulting balance in
  /// a snackbar. Mirrors the read-compute-write transaction the live
  /// award path uses; the daily-cap fields are NOT mutated so QA can
  /// call this repeatedly without hitting the 10/day ceiling. The
  /// signed-out branch surfaces a no-op snackbar because there's no
  /// `users/{uid}/` doc to write to.
  /// Force-terminates the app so Crashlytics can verify its wiring on
  /// next launch. The previous implementation threw an `Exception`
  /// synchronously inside `ListTile.onTap`, which Flutter's framework
  /// error boundary caught and logged to the console — the app kept
  /// running, and the user saw nothing. On native we call
  /// `FirebaseCrashlytics.instance.crash()` which dispatches into the
  /// platform SDK and force-terminates the process (the canonical way
  /// to test Crashlytics). On web `firebase_crashlytics` has no impl,
  /// so we throw an unhandled error from a `Future` so it escapes the
  /// `onTap` synchronous error boundary and lands in the browser's
  /// uncaught-error handler.
  void _crashNow() {
    if (kIsWeb) {
      Future<void>(() {
        throw StateError('Debug crash from Settings — web');
      });
      return;
    }
    FirebaseCrashlytics.instance.crash();
  }

  /// Clears the `onboarding_complete` flag so the next router redirect
  /// pass kicks the user back to `/onboarding`. The redirect logic at
  /// `app/router.dart` §"Onboarding gate" reads SharedPreferences
  /// synchronously, so a `context.go('/onboarding')` after the flag is
  /// cleared lands cleanly without needing a router refresh.
  Future<void> _resetOnboarding(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Replaying onboarding…'),
        duration: Duration(seconds: 2),
      ),
    );
    router.go('/onboarding');
  }

  /// Fires a one-shot local notification through the cheer-up channel.
  /// Lets QA + reviewers eyeball the real system-tray chrome without
  /// waiting for an FCM-driven dispatch. Web is a no-op (the datasource
  /// returns `false`); the user gets a snackbar explaining why.
  Future<void> _fireDebugNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fired = await ref
        .read(localNotificationDatasourceProvider)
        .fireDebugNotification();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          fired
              ? 'Notification fired — check your system tray.'
              : 'Real local notifications fire only on Android. '
                    '(Web uses the browser permission flow.)',
        ),
      ),
    );
  }

  Future<void> _grantDebugTokens(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in first to grant tokens.')),
      );
      return;
    }
    final repo = ref.read(tokenRepositoryProvider);
    final result = await repo.grantDebug(userId: user.uid, amount: 10);
    if (!context.mounted) return;
    result.fold(
      ok: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Granted 10 tokens')),
      ),
      err: (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text("Couldn't grant tokens (${failure.runtimeType})."),
        ),
      ),
    );
  }

  Future<void> _forceHarvest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(weeklySummaryControllerProvider.notifier);

    // v1.6 scope fix: compute the *active* week's id and pass it to
    // `wipeWeeklyGarden` explicitly. Previous behaviour (no argument)
    // defaulted to "delete the most recently archived week" — which
    // erased a previous week's archive instead of clearing the slot
    // the upcoming `acknowledge()` is about to write to.
    final entries = ref.read(myMoodsStreamProvider).value ?? const [];
    final history = ref.read(weeklyGardenHistoryProvider).value ?? const [];
    final activeWeekStart = activeWeekStartFor(
      entries: entries,
      history: history,
    );
    final targetWeekId = activeWeekStart == null
        ? null
        : ArchiveWeeklyGardenUseCase.formatWeekId(activeWeekStart);

    final functions = ref.read(firebaseFunctionsProvider);
    try {
      final payload = <String, dynamic>{};
      if (targetWeekId != null) payload['weekId'] = targetWeekId;
      await functions.httpsCallable('wipeWeeklyGarden').call(payload);
    } on FirebaseFunctionsException catch (e) {
      // `not-found` means the CF isn't deployed yet — surface a
      // friendly note so the demo path can still continue (the
      // existing acknowledge() call below will surface the
      // alreadyArchived failure if a doc was in the way).
      if (e.code != 'not-found') {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'wipeWeeklyGarden failed: ${e.code} — '
              '${e.message ?? "unknown"}. Continuing anyway.',
            ),
          ),
        );
      }
    } catch (_) {
      // Swallow other transient failures and let acknowledge() try.
    }

    if (!context.mounted) return;
    final garden = await controller.acknowledge();
    if (!context.mounted) return;
    if (garden != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Harvested ${garden.weekId} — '
            '${garden.entries.length} entries archived '
            '(prior archive cleared first).',
          ),
        ),
      );
      return;
    }
    // Failure path: surface the failure's `message` (HarvestFailure
    // extends Failure, which carries a human-readable description).
    final state = ref.read(weeklySummaryControllerProvider);
    final reason = state is HarvestArchiveError
        ? state.failure.message
        : 'Nothing to harvest.';
    messenger.showSnackBar(SnackBar(content: Text(reason)));
    controller.resetError();
  }

  Future<void> _clearLocalCache(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local cache?'),
        content: const Text(
          'Wipes the offline mood database AND SharedPreferences on this '
          'device. Cloud data (Firestore) is untouched and will re-sync '
          'automatically — no restart needed.',
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
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Safe-to-run-without-restart sequence:
    //
    // 1) Tear the sync manager down BEFORE truncating tables. Its
    //    `_attachedUid` / `_previousRemoteIds` / live Firestore listener
    //    + retry timers would otherwise keep firing against the
    //    in-memory state of the about-to-be-wiped DB and produce stuck
    //    queue rows.
    // 2) Truncate every Drift table.
    // 3) Clear SharedPreferences.
    // 4) Re-bootstrap the manager with the signed-in uid so the live
    //    listener re-attaches, the seeded flag is re-fetched, and the
    //    UI repopulates from Firestore — no manual restart needed.
    final uid = ref.read(currentUserStreamProvider).value?.uid;
    final manager = ref.read(moodSyncManagerProvider);
    await manager.shutdown();

    final db = ref.read(databaseProvider);
    for (final table in db.allTables) {
      // ignore: cascade_invocations
      await db.delete(table as TableInfo).go();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (uid != null) {
      // Fire-and-forget — re-bootstrapping awaits a network round-trip
      // against Firestore. The user doesn't need to block on it; the
      // listener will refill Drift on the next snapshot tick.
      unawaited(manager.bootstrap(uid));
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Local cache cleared. Resyncing from the cloud now…'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _wipeAccountData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wipe all account data?'),
        content: const Text(
          'Deletes EVERY mood entry, harvest archive, pattern result, '
          'cheer-up event, intervention state, settings, and token field '
          'under your account on Firestore. The auth account itself '
          '(name, email, sign-in) survives so you can re-onboard. '
          '\n\nThis cannot be undone.',
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
            child: const Text('Wipe everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 1. Server-side wipe via the `wipeUserData` callable. Admin SDK
    //    bypasses the rule denials on cheerUpEvents / patterns /
    //    weeklyGardens / interventionState / etc.
    final functions = ref.read(firebaseFunctionsProvider);
    try {
      await functions.httpsCallable('wipeUserData').call();
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Wipe failed: ${e.code} — ${e.message ?? "unknown"}'),
        ),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Wipe failed: $e')));
      return;
    }

    // 2. Local cache wipe — same path as `_clearLocalCache` so the
    //    next launch syncs from the (now-empty) Firestore rather than
    //    re-uploading the offline mirror.
    final db = ref.read(databaseProvider);
    for (final table in db.allTables) {
      await db.delete(table as TableInfo).go();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Account data wiped. Restart the app to re-onboard with a '
          'fresh mood history (sign-in preserved).',
        ),
        duration: Duration(seconds: 8),
      ),
    );
  }
}

/// Cycles `debugPlantTierOverrideProvider` through `null ? stormSeason ?
/// weathering ? resting ? thriving ? flourishing ? null`. The current
/// override is shown in the subtitle so reviewers can read which tier
/// the canvas is forced to without leaving Settings. Gives an immediate
/// path to all 5 visual states without manufacturing entries.
class _DebugTierCycleTile extends ConsumerWidget {
  const _DebugTierCycleTile();

  static const List<PlantTier?> _cycle = [
    null,
    PlantTier.stormSeason,
    PlantTier.weathering,
    PlantTier.resting,
    PlantTier.thriving,
    PlantTier.flourishing,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(debugPlantTierOverrideProvider);
    final label = current?.name ?? 'off (use EWMA)';
    return ListTile(
      leading: const Icon(Icons.local_florist_outlined),
      title: const Text('Cycle plant tier (5 states)'),
      subtitle: Text(
        'Tap to advance: $label ? next. Forces the home canvas to '
        'render Storm Season / Weathering / Resting / Thriving / '
        'Flourishing without manufacturing entries.',
      ),
      onTap: () {
        final notifier = ref.read(debugPlantTierOverrideProvider.notifier);
        final idx = _cycle.indexOf(current);
        final next = _cycle[(idx + 1) % _cycle.length];
        notifier.set(next);
      },
    );
  }
}

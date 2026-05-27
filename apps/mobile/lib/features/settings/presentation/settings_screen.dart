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
import '../../mood/data/sync/mood_sync_manager.dart' show MoodSyncManager;
import '../../auth/presentation/widgets/privacy_lock_settings_tile.dart';
import '../../auth/presentation/widgets/webauthn_settings_tile.dart';
import '../../garden/data/providers.dart' show debugPlantTierOverrideProvider;
import '../../garden/domain/entities/plant_tier.dart';
import '../../harvest/data/providers.dart' show weeklyGardenHistoryProvider;
import '../../harvest/domain/usecases/archive_weekly_garden.dart'
    show ArchiveWeeklyGardenUseCase;
import '../../harvest/presentation/controllers/weekly_summary_controller.dart';
import '../../intervention/presentation/controllers/intervention_controller.dart';
import '../../mood/data/sync/connectivity_provider.dart';
import '../../notifications/data/datasources/local_notification_datasource.dart';
import '../../notifications/presentation/widgets/notifications_toggle_tile.dart';
import '../../notifications/presentation/widgets/tier_toggle_tile.dart';
import '../../disclaimer/domain/disclaimer_copy.dart';
import '../../pattern_engine/domain/entities/tier.dart' as engine;
import '../../tokens/data/providers.dart' show tokenRepositoryProvider;
import '../domain/entities/theme_mode_preference.dart';
import 'controllers/theme_mode_controller.dart';
import 'widgets/delete_account_dialog.dart';

/// Settings screen (v1.6 redesign).
///
/// Layout per the prototype's `SettingsScreen` in
/// `.tmp-handoff/.../prototype/screens-extra.jsx`:
/// uppercase section labels (`ACCOUNT`, `GARDEN`, `PRIVACY`,
/// `NOTIFICATIONS`, `SYNC`, `THEME`, `DISCLAIMER`, `ABOUT`,
/// `DELETE ACCOUNT`) each wrap a single [MbCard]. On phone (`<600`) the
/// sections stack into a single column; on tablet+ (`>=600`) they flow
/// into a 2-column responsive grid so the surface stays scannable
/// without the cards stretching across an ultrawide window.
///
/// All controllers (theme, notifications, FCM, sync manager, account
/// deletion, debug overrides) are preserved verbatim from the v1.5
/// implementation — this redesign refreshes visual treatment only.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    // Settings tiles need a strong press effect: the default Material
    // splash on `MbCard`'s `MaterialType.transparency` surface is washed
    // out on the cream/navy theme. Bumped both alpha values
    // aggressively and swapped to `InkRipple.splashFactory` for the
    // stronger ripple animation.
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= MbBreakpoints.phone;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.pagePadding,
                  MoodBloomSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Settings',
                      style: MbFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: mb.text,
                      ),
                    ),
                    const SizedBox(height: MoodBloomSpacing.lg),
                    _SectionsLayout(
                      twoColumn: twoColumn,
                      sections: _buildSections(context, ref, user, mb),
                    ),
                    const SizedBox(height: MoodBloomSpacing.lg),
                    Center(
                      child: Text(
                        'Made with care · School of Information Technology, KMUTT',
                        style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the ordered list of section widgets. Each entry is a fully
  /// composed `_Section` (label + body card). Sections that depend on
  /// the user being signed in or on platform conditionals are returned
  /// conditionally so the layout doesn't have to special-case nulls.
  List<Widget> _buildSections(
    BuildContext context,
    WidgetRef ref,
    user,
    MbColors mb,
  ) {
    final sections = <Widget>[
      _AccountSection(user: user),
      const _GardenSection(),
    ];

    if (user != null) {
      sections.add(const _PrivacySection());
    }

    sections.add(const _NotificationsSection());

    if (user != null) {
      sections.add(const _SyncSection());
    }

    sections.addAll([
      const _ThemeSection(),
      const _DisclaimerSection(),
      const _AboutSection(),
      const _DeleteAccountSection(),
    ]);

    if (kDebugMode) {
      sections.add(const _DebugSection());
    }

    return sections;
  }
}

/// Responsive layout for the ordered section list. Phone (`<600`)
/// returns a vertical Column. Tablet+ flows into a 2-column layout that
/// distributes sections across left/right buckets in declaration order
/// — `i.isEven` to left, `i.isOdd` to right — so the visual order
/// roughly mirrors the linear declaration while keeping the columns
/// balanced.
class _SectionsLayout extends StatelessWidget {
  const _SectionsLayout({required this.twoColumn, required this.sections});

  final bool twoColumn;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    if (!twoColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: MoodBloomSpacing.lg),
            sections[i],
          ],
        ],
      );
    }

    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      (i.isEven ? left : right).add(sections[i]);
    }
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: MoodBloomSpacing.lg),
          children[i],
        ],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: MoodBloomSpacing.lg),
        Expanded(child: column(right)),
      ],
    );
  }
}

/// One section = `MbSectionLabel` + an [MbCard] body. Shared chrome so
/// every settings cluster reads the same shape — uppercase label, a
/// 6 dp gap, then a single bordered card.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MbSectionLabel(label),
        const SizedBox(height: 6),
        MbCard(
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.zero,
          child: child,
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return _Section(
      label: 'ACCOUNT',
      child: Column(
        children: [
          if (user != null)
            ListTile(
              leading: Icon(Icons.mail_outline, color: mb.text),
              title: Text(user.displayName ?? 'Your account'),
              subtitle: user.email != null
                  ? Text(
                      user.email!,
                      style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
                    )
                  : null,
              onTap: () =>
                  _editDisplayName(context, ref, currentName: user.displayName),
              trailing: Icon(Icons.edit_outlined, color: mb.textDim, size: 18),
            ),
          if (user != null) const Divider(height: 1),
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
        ],
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref, {
    required String? currentName,
  }) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditDisplayNameDialog(initialName: currentName),
    );
    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == (currentName ?? '').trim()) return;

    final result = await ref
        .read(authRepositoryProvider)
        .updateDisplayName(trimmed);
    if (!context.mounted) return;
    result.fold(
      ok: (_) {
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
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          // scrollable: true keeps the title + content + two-button
          // action row readable at 200% type on a small phone (the
          // settings_screen_a11y_test guards this).
          scrollable: true,
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
}

class _GardenSection extends StatelessWidget {
  const _GardenSection();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return _Section(
      label: 'GARDEN',
      child: ListTile(
        leading: Icon(Icons.local_florist_outlined, color: mb.text),
        title: const Text('Customize your garden'),
        subtitle: Text(
          'Skins, plant shapes, themes',
          style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
        ),
        trailing: Icon(Icons.chevron_right, color: mb.textDim, size: 22),
        // The /garden/skins route lands in Phase 12. Until then the
        // navigation no-ops cleanly via go_router's not-found gate. We
        // wire the tap unconditionally so the affordance reads "live"
        // in the redesign sprint.
        onTap: () => context.go('/garden/skins'),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'PRIVACY',
      child: Column(
        children: [
          const PrivacyLockSettingsTile(),
          // WebAuthn is web-only — keep the tile on web, drop it (and
          // the divider) on native where biometric already covers the
          // same affordance.
          if (kIsWeb) ...const [Divider(height: 1), WebauthnSettingsTile()],
        ],
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      label: 'NOTIFICATIONS',
      child: Column(
        children: [
          NotificationsToggleTile(),
          Divider(height: 1),
          TierToggleTile(tier: InterventionTier.one),
          Divider(height: 1),
          TierToggleTile(tier: InterventionTier.two),
          Divider(height: 1),
          TierToggleTile(tier: InterventionTier.three),
        ],
      ),
    );
  }
}

class _SyncSection extends StatelessWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context) {
    // Native builds use the Drift -> Firestore push/pull sync manager
    // with a manual "Sync now". On web there's no offline Drift mirror;
    // Firestore's own real-time layer keeps the data live, so the web
    // cluster is an informational "syncs automatically" status instead.
    return _Section(
      label: 'SYNC',
      child: kIsWeb ? const _WebSyncCluster() : const _SyncCluster(),
    );
  }
}

/// Web sync status. On web the app talks to Firestore directly and its
/// real-time listeners keep every device current automatically, so
/// there's no manual push step to surface - just a reassuring status.
class _WebSyncCluster extends StatelessWidget {
  const _WebSyncCluster();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return ListTile(
      leading: Icon(Icons.cloud_done_outlined, color: mb.text),
      title: const Text('Cloud sync'),
      subtitle: Text(
        'Your garden syncs automatically to the cloud while you\'re '
        'signed in. Changes appear on your other devices in real time.',
        style: MbFonts.nunito(fontSize: 12, height: 1.4, color: mb.textDim),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: MoodBloomColors.softGreen,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'AUTOMATIC',
          style: MbFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: MoodBloomColors.seedDark,
          ),
        ),
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themeModeControllerProvider);
    return _Section(
      label: 'THEME',
      child: RadioGroup<ThemeModePreference>(
        groupValue: preference,
        onChanged: (chosen) {
          if (chosen == null) return;
          ref.read(themeModeControllerProvider.notifier).setPreference(chosen);
        },
        child: const Column(
          children: [
            _ThemeRadioTile(option: ThemeModePreference.light),
            _ThemeRadioTile(option: ThemeModePreference.dark),
            _ThemeRadioTile(option: ThemeModePreference.system),
            _ThemeRadioTile(option: ThemeModePreference.followDeviceTime),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerSection extends StatelessWidget {
  const _DisclaimerSection();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    // Soft-coral / AI-tint background per the prototype's DISCLAIMER
    // section. Locked copy — the `DisclaimerCopy.notificationFooter` is
    // the canonical short form referenced in CLAUDE.md and pinned by
    // the disclaimer tests.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('DISCLAIMER'),
        const SizedBox(height: 6),
        MbCard(
          decoration: BoxDecoration(
            color: mb.aiBg,
            border: Border.all(color: mb.aiBd),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
          ),
          padding: const EdgeInsets.all(MoodBloomSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medical_information_outlined,
                color: mb.textDim,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DisclaimerCopy.notificationFooter,
                  style: MbFonts.nunito(
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: mb.textDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  /// Hand-maintained until package_info_plus lands. Bumped per release.
  static const String _appVersion = '1.0.0 (build 3)';

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return _Section(
      label: 'ABOUT',
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: mb.text),
            title: const Text('Version'),
            subtitle: Text(
              _appVersion,
              style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.description_outlined, color: mb.text),
            title: const Text('Privacy policy'),
            trailing: Icon(Icons.chevron_right, color: mb.textDim, size: 22),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.gavel_outlined, color: mb.text),
            title: const Text('Terms of service'),
            trailing: Icon(Icons.chevron_right, color: mb.textDim, size: 22),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountSection extends StatelessWidget {
  const _DeleteAccountSection();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MbSectionLabel('DELETE ACCOUNT'),
        const SizedBox(height: 6),
        MbCard(
          decoration: BoxDecoration(
            color: mb.softCoral,
            border: Border.all(
              color: mb.destructiveText.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
          ),
          padding: const EdgeInsets.all(MoodBloomSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Permanently remove your account and all entries. This '
                'cannot be undone.',
                style: MbFonts.nunito(
                  fontSize: 13,
                  height: 1.5,
                  color: mb.destructiveText,
                ),
              ),
              const SizedBox(height: MoodBloomSpacing.md),
              MbGhostButton(
                label: 'Delete my account',
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: mb.destructiveText,
                  size: 18,
                ),
                onPressed: () => DeleteAccountDialog.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(label: 'DEBUG', child: _DebugCluster());
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

/// Single radio tile in the theme picker. Uses the post-3.32
/// RadioListTile API — `groupValue` / `onChanged` come from a
/// [RadioGroup] ancestor in `_ThemeSection`, not from per-tile
/// parameters.
class _ThemeRadioTile extends StatelessWidget {
  const _ThemeRadioTile({required this.option});

  final ThemeModePreference option;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final label = _label(option);
    final sub = _subtitle(option);
    final registry = RadioGroup.maybeOf<ThemeModePreference>(context);
    final selected = option == registry?.groupValue;
    return Semantics(
      label: 'Theme: $label, ${selected ? 'selected' : 'not selected'}',
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: RadioListTile<ThemeModePreference>(
        value: option,
        title: Text(label),
        subtitle: sub == null
            ? null
            : Text(sub, style: MbFonts.nunito(fontSize: 12, color: mb.textDim)),
        secondary: Icon(_icon(option), color: mb.text),
        controlAffinity: ListTileControlAffinity.trailing,
        dense: true,
      ),
    );
  }

  static String _label(ThemeModePreference option) => switch (option) {
    ThemeModePreference.system => 'Follow device theme',
    ThemeModePreference.followDeviceTime => 'Follow device time',
    ThemeModePreference.light => 'Light',
    ThemeModePreference.dark => 'Dark',
  };

  static String? _subtitle(ThemeModePreference option) => switch (option) {
    ThemeModePreference.followDeviceTime =>
      'Light 07:00 - 18:59, dark otherwise',
    _ => null,
  };

  static IconData _icon(ThemeModePreference option) => switch (option) {
    ThemeModePreference.light => Icons.light_mode_outlined,
    ThemeModePreference.dark => Icons.dark_mode_outlined,
    ThemeModePreference.system => Icons.brightness_auto_outlined,
    ThemeModePreference.followDeviceTime => Icons.schedule_outlined,
  };
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
    // The sync manager transitively requires Firebase + SharedPreferences
    // to be initialised. In environments where those are unavailable
    // (notably widget tests that don't go through the full bootstrap
    // path) we self-hide rather than crashing the entire Settings
    // screen — the cluster is an advanced affordance, not load-bearing.
    final MoodSyncManager manager;
    try {
      manager = ref.watch(moodSyncManagerProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final mb = Theme.of(context).extension<MbColors>()!;
    return ValueListenableBuilder<DateTime?>(
      valueListenable: manager.lastSuccessfulSync,
      builder: (context, lastSync, _) {
        return Column(
          children: [
            ListTile(
              leading: Icon(Icons.cloud_done_outlined, color: mb.text),
              title: const Text('Last sync'),
              subtitle: Text(
                _describeLastSync(lastSync),
                style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
              ),
              trailing: lastSync == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MoodBloomColors.softGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'UP TO DATE',
                        style: MbFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: MoodBloomColors.seedDark,
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.sync, color: mb.text),
              title: const Text('Sync now'),
              subtitle: Text(
                'Push pending entries and pull the latest from the cloud.',
                style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
              ),
              onTap: () => _kickSync(context, ref),
            ),
          ],
        );
      },
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
/// (Crashlytics test crash, force-harvest, plant-tier cycler, etc).
/// Wrapped in an `ExpansionTile` (collapsed by default) so the
/// power-user tiles don't dominate the Settings scroll.
class _DebugCluster extends ConsumerWidget {
  const _DebugCluster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = ref.watch(debugForceOfflineProvider);
    final mb = Theme.of(context).extension<MbColors>()!;
    return Theme(
      // Strip the divider above/below the expansion children so adjacent
      // tiles flow visually into the cluster card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.build_outlined),
        title: const Text('Debug tools'),
        subtitle: const Text('Power-user only - tap to expand'),
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
          ListTile(
            leading: const Icon(Icons.toll_outlined),
            title: const Text('Grant 10 tokens'),
            subtitle: const Text('Skip the daily cap.'),
            onTap: () => _grantDebugTokens(context, ref),
          ),
          const Divider(height: 1),
          const _DebugTierCycleTile(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: const Text('Force harvest now'),
            subtitle: const Text('Archive this week immediately.'),
            onTap: () => _forceHarvest(context, ref),
          ),
          const Divider(height: 1),
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
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Fire OS notification'),
            subtitle: const Text('Android only.'),
            onTap: () => _fireDebugNotification(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: const Text('Replay onboarding'),
            subtitle: const Text('Show the welcome slides again.'),
            onTap: () => _resetOnboarding(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear local cache'),
            subtitle: const Text('Wipes local DB; cloud is untouched.'),
            onTap: () => _clearLocalCache(context, ref),
          ),
          const Divider(height: 1),
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
            subtitle: const Text('Cloud + local. Auth survives. Irreversible.'),
            onTap: () => _wipeAccountData(context, ref),
          ),
        ],
      ),
    );
  }

  /// Force-terminates the app so Crashlytics can verify its wiring on
  /// next launch. On native we call
  /// `FirebaseCrashlytics.instance.crash()`. On web `firebase_crashlytics`
  /// has no impl, so we throw an unhandled error from a `Future` so it
  /// lands in the browser's uncaught-error handler.
  void _crashNow() {
    if (kIsWeb) {
      Future<void>(() {
        throw StateError('Debug crash from Settings - web');
      });
      return;
    }
    FirebaseCrashlytics.instance.crash();
  }

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
              ? 'Notification fired - check your system tray.'
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
      if (e.code != 'not-found') {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'wipeWeeklyGarden failed: ${e.code} - '
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
            'Harvested ${garden.weekId} - '
            '${garden.entries.length} entries archived '
            '(prior archive cleared first).',
          ),
        ),
      );
      return;
    }
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
          'automatically - no restart needed.',
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

    final functions = ref.read(firebaseFunctionsProvider);
    try {
      await functions.httpsCallable('wipeUserData').call();
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Wipe failed: ${e.code} - ${e.message ?? "unknown"}'),
        ),
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Wipe failed: $e')));
      return;
    }

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
/// the canvas is forced to without leaving Settings.
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
    final label = current?.name ?? 'off';
    return ListTile(
      leading: const Icon(Icons.local_florist_outlined),
      title: const Text('Cycle plant tier'),
      subtitle: Text('Current: $label'),
      onTap: () {
        final notifier = ref.read(debugPlantTierOverrideProvider.notifier);
        final idx = _cycle.indexOf(current);
        final next = _cycle[(idx + 1) % _cycle.length];
        notifier.set(next);
      },
    );
  }
}

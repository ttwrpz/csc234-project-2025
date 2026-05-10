import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift/drift.dart' show TableInfo;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../auth/data/providers.dart';
import '../../mood/data/providers.dart' show firebaseFunctionsProvider;
import '../../auth/presentation/widgets/biometric_settings_tile.dart';
import '../../disclaimer/presentation/widgets/disclaimer_panel.dart';
import '../../garden/data/providers.dart' show debugPlantTierOverrideProvider;
import '../../garden/domain/entities/plant_tier.dart';
import '../../harvest/presentation/controllers/weekly_summary_controller.dart';
import '../../mood/data/sync/connectivity_provider.dart';
import '../../notifications/presentation/widgets/notifications_toggle_tile.dart';
import '../../tokens/presentation/controllers/token_visibility_controller.dart';
import '../domain/entities/theme_mode_preference.dart';
import 'controllers/theme_mode_controller.dart';

/// Settings screen — restyled in Phase C and re-grouped in this round so
/// related preferences live in clearly-zoned [MbCard] clusters: Profile,
/// Preferences, Account (sign-out, with confirmation dialog), and a
/// Debug zone (only in debug builds).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final themePreference = ref.watch(themeModeControllerProvider);
    final mb = Theme.of(context).extension<MbColors>()!;

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
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
            if (user != null)
              MbCard(
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
                            user.displayName ?? 'Signed in',
                            style: MbFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: mb.text,
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
            const MbSectionLabel('SECURITY'),
            const SizedBox(height: 6),
            MbCard(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.zero,
              child: const BiometricSettingsTile(),
            ),

            const SizedBox(height: 18),

            // ── Account zone ──
            const MbSectionLabel('ACCOUNT'),
            const SizedBox(height: 6),
            MbCard(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: MoodBloomColors.coralText,
                ),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: MoodBloomColors.coralText,
                    fontWeight: FontWeight.w600,
                    shadows: <Shadow>[],
                  ),
                ),
                onTap: () => _confirmSignOut(context, ref),
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
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
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
              backgroundColor: MoodBloomColors.coral,
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

  static String _avatarInitial(String? displayName, String? email) {
    final source = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : email?.trim() ?? '?';
    return source.substring(0, 1).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // explicit always-on choices. Matches HB-005 §Track 4.4/7.2.
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
          // Anti-pattern guardrail (HB-005 Track 6.2, ADR-0010 §7):
          // visibility toggle, NEVER an opt-out of earning. Tokens
          // still accumulate in the background when this is off — only
          // the chip render on the garden home is suppressed.
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
          const NotificationsToggleTile(),
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

/// About zone — application metadata for the demo. Version string is a
/// hard-coded constant for now; once the app graduates from Sprint 2 we
/// can read it from `package_info_plus` instead. Keeping it inline avoids
/// the extra dependency on a single string.
///
/// The Medical disclaimer expansion tile (S5 feature 7.4 — pulled
/// forward) lives at the bottom of the cluster so the version line
/// stays the cluster's primary affordance. The expansion only opens on
/// explicit tap; the disclaimer text is never auto-shown here.
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

/// Debug zone, only rendered in debug builds. Bundles existing tools
/// (Crashlytics test crash) plus a "Force offline" toggle that lets QA
/// simulate the no-Wi-Fi flow without touching the device's radios.
class _DebugCluster extends ConsumerWidget {
  const _DebugCluster();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = ref.watch(debugForceOfflineProvider);
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.wifi_off_outlined),
            title: const Text('Force offline'),
            subtitle: const Text(
              'Simulates a dropped network for the rest of this session.',
            ),
            value: forced,
            onChanged: (v) =>
                ref.read(debugForceOfflineProvider.notifier).set(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Crash now'),
            subtitle: const Text(
              'Throws a non-fatal error to verify Crashlytics wiring.',
            ),
            onTap: () {
              throw Exception(
                'Crashlytics test crash from Settings — debug only',
              );
            },
          ),
          const Divider(height: 1),
          // Cycle the plant tier through the 5 ecosystem states
          // (Storm Season → Weathering → Resting → Thriving → Flourishing
          // → off). The override is held by `debugPlantTierOverrideProvider`
          // and short-circuits the EWMA-derived tier at the
          // `gardenStateStreamProvider` level — no entries needed,
          // visual states stay reproducible for QA + reviewers.
          const _DebugTierCycleTile(),
          const Divider(height: 1),
          // Force-harvest tile (HB-005 Track 6.1 demo affordance).
          // Bypasses the 7-day boundary check so QA + demo can run the
          // archive flow without waiting for a Monday rollover. Calls
          // the same `acknowledge()` path as the production
          // WeeklySummaryScreen Continue button — the only difference
          // is the entry point (a debug ListTile vs the
          // pendingWeeklySummaryProvider-driven push).
          ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: const Text('Force harvest now'),
            subtitle: const Text(
              'Archive the current active week immediately, regardless of '
              'the 7-day boundary. Debug only.',
            ),
            onTap: () => _forceHarvest(context, ref),
          ),
          const Divider(height: 1),
          // Clear local cache + offline DB. User asked for this in
          // v1.0 polish to investigate "no flower on negative render"
          // bug — to rule out stale Drift / SharedPreferences state.
          // Wipes all rows from the Drift mood DB (mood_entries +
          // sync_queue) and clears every key in SharedPreferences.
          // Does NOT sign the user out (Firebase Auth state is owned
          // by FirebaseAuth, separate from local cache); does NOT
          // touch Firestore. After clearing, recommends an app restart
          // because Riverpod providers + Drift open handles cache the
          // wiped state in memory.
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear local cache'),
            subtitle: const Text(
              'Wipes Drift mood DB + SharedPreferences. Cloud data is '
              'untouched. Restart the app afterwards.',
            ),
            onTap: () => _clearLocalCache(context, ref),
          ),
          const Divider(height: 1),
          // Wipe all CLOUD data for the signed-in user via the
          // `wipeUserData` Cloud Function (admin SDK). Most subcollection
          // rules deny client deletes (cheerUpEvents append-only,
          // patterns delete-denied, weeklyGardens write-once, etc), so
          // a full reset has to go through admin SDK. Auth account
          // (displayName / email / photoUrl / createdAt) survives —
          // the user stays signed in and can re-onboard with a fresh
          // mood history. Local Drift + SharedPrefs are also wiped so
          // the next launch syncs from the (now-empty) cloud rather
          // than re-uploading the offline mirror.
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: MoodBloomColors.coralText,
            ),
            title: const Text(
              'Wipe all account data',
              style: TextStyle(
                color: MoodBloomColors.coralText,
                fontWeight: FontWeight.w600,
                shadows: <Shadow>[],
              ),
            ),
            subtitle: const Text(
              'Wipes EVERY mood / harvest / pattern / event under '
              'users/{uid}/ on Firestore plus the local cache. Account '
              'profile + sign-in survive. Debug only.',
            ),
            onTap: () => _wipeAccountData(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _forceHarvest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(weeklySummaryControllerProvider.notifier);

    // v1.0 polish (2026-05-10): clear the most recent weeklyGarden
    // archive first so the force-harvest button is replay-able.
    // Without this, the second tap fails with "alreadyArchived"
    // because production rules treat the archive as write-once.
    // The `wipeWeeklyGarden` callable bypasses the delete: false
    // rule via Admin SDK and is debug-only.
    final functions = ref.read(firebaseFunctionsProvider);
    try {
      await functions.httpsCallable('wipeWeeklyGarden').call();
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
          'device. Cloud data (Firestore) is untouched and will re-sync. '
          'This is a debug affordance — restart the app afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MoodBloomColors.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 1. Truncate every Drift table on the mood DB. We iterate
    //    `db.allTables` rather than naming `MoodEntries` /
    //    `SyncQueue` directly so that future schema additions don't
    //    silently leave rows on disk.
    final db = ref.read(databaseProvider);
    for (final table in db.allTables) {
      // ignore: cascade_invocations
      await db.delete(table as TableInfo).go();
    }

    // 2. Clear SharedPreferences. Resolved synchronously via the
    //    pre-warmed singleton; if it's not warm yet the
    //    `instance.clear()` call still works.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Local cache cleared. Restart the app to see a fresh state.',
        ),
        duration: Duration(seconds: 6),
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
              backgroundColor: MoodBloomColors.coral,
              foregroundColor: Colors.white,
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
/// the canvas is forced to without leaving Settings. v1.0 polish
/// (2026-05-10) � addresses "Garden Health stuck at Resting" feedback
/// by giving the user an immediate path to all 5 visual states.
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

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/providers.dart';
import '../../auth/presentation/widgets/biometric_settings_tile.dart';
import '../../mood/data/sync/connectivity_provider.dart';
import '../../notifications/presentation/widgets/notifications_toggle_tile.dart';
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
    final themeMode = ref.watch(themeModeControllerProvider);
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
            _PreferencesCluster(themeMode: themeMode),

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
                leading: Icon(Icons.logout, color: MoodBloomColors.coral),
                title: Text(
                  'Sign out',
                  style: TextStyle(
                    color: MoodBloomColors.coral,
                    fontWeight: FontWeight.w600,
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
  const _PreferencesCluster({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode == null) return;
                ref.read(themeModeControllerProvider.notifier).setMode(mode);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(height: 1),
          const NotificationsToggleTile(),
        ],
      ),
    );
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Match the system',
    ThemeMode.light => 'Always light',
    ThemeMode.dark => 'Always dark',
  };
}

/// About zone — application metadata for the demo. Version string is a
/// hard-coded constant for now; once the app graduates from Sprint 2 we
/// can read it from `package_info_plus` instead. Keeping it inline avoids
/// the extra dependency on a single string.
class _AboutCluster extends StatelessWidget {
  const _AboutCluster();

  /// Hand-maintained until package_info_plus lands. Bumped per release.
  static const String _appVersion = 'Beta 0.5';

  @override
  Widget build(BuildContext context) {
    return MbCard(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('MoodBloom'),
        subtitle: Text('Version $_appVersion'),
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
        ],
      ),
    );
  }
}

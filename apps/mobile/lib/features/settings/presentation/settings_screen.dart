import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/providers.dart';
import '../../auth/presentation/widgets/biometric_settings_tile.dart';
import 'controllers/theme_mode_controller.dart';

/// Settings screen — extracted from `app/router.dart:221-271` (S3) in
/// Sprint 4 WBS 6.2 Day 2. Hosts all user-facing preferences. The
/// Appearance section (theme-mode dropdown) is the new addition; account
/// row, sign-out, biometric tile, and the debug crash button are
/// preserved verbatim from the in-file S3 version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final displayName = user?.displayName;
    final themeMode = ref.watch(themeModeControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MoodBloomSpacing.lg,
              MoodBloomSpacing.lg,
              MoodBloomSpacing.lg,
              MoodBloomSpacing.sm,
            ),
            child: Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (mode) {
                if (mode == null) return;
                // Fire-and-forget: state updates synchronously; the
                // SharedPreferences write resolves in the background.
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
          const Divider(),
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

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Match the system',
    ThemeMode.light => 'Always light',
    ThemeMode.dark => 'Always dark',
  };
}

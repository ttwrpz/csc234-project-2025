import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/confirmation_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                        backgroundImage: auth.user?.photoURL != null
                            ? NetworkImage(auth.user!.photoURL!)
                            : null,
                        child: auth.user?.photoURL == null
                            ? const Text(
                                '\u{1F331}',
                                style: TextStyle(fontSize: 28),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.displayName ??
                                  auth.userProfile?.displayName ??
                                  'User',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.email ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editProfile(context, auth),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Garden settings
              _SectionHeader(title: 'Garden'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bug Fade Speed'),
                          Text(
                            '${settings.animationSpeed.toStringAsFixed(1)}x',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.animationSpeed,
                        min: AppConstants.minAnimationSpeed,
                        max: AppConstants.maxAnimationSpeed,
                        divisions: 8,
                        label: '${settings.animationSpeed.toStringAsFixed(1)}x',
                        onChanged: (value) => settings.setAnimationSpeed(value),
                      ),
                      Text(
                        'Controls how fast negative mood bugs fade away',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Appearance
              _SectionHeader(title: 'Appearance'),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: settings.darkMode,
                  onChanged: (value) => settings.setDarkMode(value),
                  secondary: Icon(
                    settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notifications
              _SectionHeader(title: 'Notifications'),
              Card(
                child: SwitchListTile(
                  title: const Text('Daily Mood Reminder'),
                  subtitle: const Text('Get a daily reminder to log your mood'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotificationsEnabled(value),
                ),
              ),
              const SizedBox(height: 16),

              // Data & Sync
              _SectionHeader(title: 'Data & Sync'),
              _SyncSection(),
              const SizedBox(height: 16),

              // Data & Privacy
              _SectionHeader(title: 'Data & Privacy'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: const Text('Delete Account'),
                      subtitle: const Text('Permanently delete all your data'),
                      onTap: () => _deleteAccount(context, auth),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // About
              _SectionHeader(title: 'About'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About MoodBloom'),
                      subtitle: const Text('Version 0.2.0'),
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              OutlinedButton.icon(
                onPressed: () => _logout(context, auth),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AuthProvider auth) async {
    final controller = TextEditingController(
      text: auth.user?.displayName ?? auth.userProfile?.displayName ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await auth.updateDisplayName(result);
    }
  }

  Future<void> _deleteAccount(BuildContext context, AuthProvider auth) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? All your data will be permanently removed. This action cannot be undone.',
      confirmText: 'Delete Account',
      isDestructive: true,
    );
    if (!confirmed) return;

    final success = await auth.deleteAccount();
    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
    } else if (context.mounted && auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
    );
    if (!confirmed) return;

    await auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('\u{1F33B} ', style: TextStyle(fontSize: 24)),
            Text(
              'MoodBloom',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        content: const Text(
          'MoodBloom is a mood tracking app that turns your emotions into a virtual garden. '
          'Log how you feel daily, and watch positive moods grow flowers while negative moods '
          'bring bugs that fade away over time.\n\n'
          'Built for CSC231 & CSC234 coursework.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SyncSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moodProvider = context.watch<MoodProvider>();
    final pendingCount = moodProvider.pendingSyncCount;
    final lastSync = moodProvider.lastSyncTime;

    String lastSyncText;
    if (lastSync == null) {
      lastSyncText = 'Never';
    } else {
      final diff = DateTime.now().difference(lastSync);
      if (diff.inMinutes < 1) {
        lastSyncText = 'Just now';
      } else if (diff.inHours < 1) {
        lastSyncText = '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      } else if (diff.inDays < 1) {
        lastSyncText = '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
      } else {
        lastSyncText = '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pendingCount > 0 ? Icons.sync_problem : Icons.cloud_done,
                  size: 20,
                  color: pendingCount > 0
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  pendingCount > 0
                      ? '$pendingCount entr${pendingCount == 1 ? 'y' : 'ies'} pending sync'
                      : 'All entries synced',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last synced: $lastSyncText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: moodProvider.isLoading
                    ? null
                    : () => _syncNow(context),
                icon: const Icon(Icons.sync, size: 18),
                label: Text(moodProvider.isLoading ? 'Syncing...' : 'Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final moodProvider = context.read<MoodProvider>();
    if (auth.user != null) {
      await moodProvider.refreshEntries(auth.user!.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

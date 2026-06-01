import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/daily_check_in_controller.dart';

/// Settings cluster for the self-set daily check-in reminder: a switch
/// plus a "Reminder time" sub-row that opens [showTimePicker]. The time
/// row is greyed and inert while the toggle is off.
///
/// This is a purely local, self-set nudge to log a mood - distinct from
/// the FCM-driven "Support reminders" (Tier 3) above it. On enable or time
/// change the controller requests OS permission and arms a real daily
/// local notification; on disable it cancels it.
class DailyCheckInTile extends ConsumerWidget {
  const DailyCheckInTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(dailyCheckInControllerProvider);
    final notifier = ref.read(dailyCheckInControllerProvider.notifier);
    final timeLabel = _formatTime(context, schedule.hour, schedule.minute);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.alarm_outlined),
          title: const Text('Daily check-in'),
          subtitle: const Text(
            'A quiet daily reminder to log how you feel. Off until you grant '
            'notification permission.',
          ),
          value: schedule.enabled,
          onChanged: (v) => notifier.setEnabled(v),
        ),
        ListTile(
          enabled: schedule.enabled,
          leading: const SizedBox(width: 24),
          title: const Text('Reminder time'),
          trailing: Text(timeLabel),
          onTap: schedule.enabled ? () => _pickTime(context, ref) : null,
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(dailyCheckInControllerProvider.notifier);
    final current = ref.read(dailyCheckInControllerProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Pick your reminder time',
    );
    if (picked == null) return;
    await notifier.setTime(hour: picked.hour, minute: picked.minute);
  }

  /// Formats the stored 24h time using the device's preferred 12/24h
  /// convention via [MaterialLocalizations.formatTimeOfDay].
  String _formatTime(BuildContext context, int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }
}

import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final bool isSynced;

  const SyncIndicator({super.key, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isSynced ? 'Synced to cloud' : 'Saved locally, pending sync',
      child: Icon(
        isSynced ? Icons.cloud_done_outlined : Icons.phone_android,
        size: 14,
        color: isSynced
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
      ),
    );
  }
}

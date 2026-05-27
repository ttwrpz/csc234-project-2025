import 'package:flutter/material.dart';

import '../../domain/entities/garden_skin.dart';

/// Modal confirmation dialog for the spend flow. Used by the legacy
/// skin-modal redirect path - the new Phase 12 flow prefers
/// [SkinPurchaseConfirmSheet] which has the full preview + cost
/// breakdown.
///
/// Wording: `"Spend N tokens to unlock {displayName}?"`,
/// `[Cancel]` / `[Confirm]`. Cancel returns `false`; Confirm returns
/// `true`; tapping the scrim is treated as cancel.
///
/// CLAUDE.md copy rules upheld: no fix-your-mood verbs, no
/// streak-shaming, compassionate-imperative phrasing.
class SpendConfirmationDialog extends StatelessWidget {
  const SpendConfirmationDialog({super.key, required this.skin});

  final GardenSkin skin;

  /// Convenience launcher mirroring `showDialog<bool>` so callers can
  /// `final ok = await SpendConfirmationDialog.show(context, skin: ...)`
  /// without re-typing the dialog wiring.
  static Future<bool> show(
    BuildContext context, {
    required GardenSkin skin,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SpendConfirmationDialog(skin: skin),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Unlock this skin?'),
      content: Text(
        'Spend ${skin.cost} tokens to unlock ${skin.displayName}?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

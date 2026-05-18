import 'package:flutter/material.dart';

/// Modal confirmation dialog for the spend flow.
///
/// Wording per the brief: `"Spend N tokens to unlock {displayName}?"`,
/// `[Cancel]` / `[Confirm]`. Cancel returns `false`; Confirm returns
/// `true`; tapping the scrim is treated as cancel.
///
/// Resolves to a boolean indicating whether the user confirmed. Stateful
/// caller (the [SkinModalSheet]) reads the result and, on `true`, runs
/// the [UnlockFlowerSkinUseCase] then closes the dialog by way of the
/// snackbar success path; on `false` the modal stays open with the
/// balance unchanged.
///
/// CLAUDE.md copy rules upheld: no fix-your-mood verbs, no
/// streak-shaming, compassionate-imperative phrasing ("Spend N tokens
/// to unlock?" is offered, not commanded).
class SpendConfirmationDialog extends StatelessWidget {
  const SpendConfirmationDialog({
    super.key,
    required this.cost,
    required this.skinName,
  });

  final int cost;
  final String skinName;

  /// Convenience launcher mirroring `showDialog<bool>` so callers can
  /// `final ok = await SpendConfirmationDialog.show(context, …)`
  /// without re-typing the dialog wiring.
  static Future<bool> show(
    BuildContext context, {
    required int cost,
    required String skinName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          SpendConfirmationDialog(cost: cost, skinName: skinName),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Unlock this skin?'),
      content: Text(
        'Spend $cost tokens to unlock $skinName?',
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

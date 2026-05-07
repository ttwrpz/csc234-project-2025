import 'package:flutter/material.dart';

/// Confirmation modal for the Settings → Danger zone "Delete account" row.
///
/// HB-004 + O12: copy is locked verbatim — the body and primary button
/// labels are byte-identical to the brief. No typed-DELETE step;
/// reauth (handled by the controller after this modal returns true) is
/// the security gate.
///
/// Returns `true` from `Navigator.pop` when the user confirms; returns
/// `null` (or `false`) on dismiss / Cancel. The controller pattern:
///
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => const DeleteAccountModal(),
/// );
/// if (confirmed == true) { /* prompt reauth, run use case */ }
/// ```
class DeleteAccountModal extends StatelessWidget {
  const DeleteAccountModal({super.key});

  /// Body copy — locked verbatim per HB-004 + O12. Exposed as a static
  /// constant so the widget test can assert exact equality without
  /// duplicating the string literal.
  static const String bodyText =
      'This permanently deletes your account, all entries, and photos. '
      'This cannot be undone.';

  /// Primary destructive button label — locked verbatim per HB-004.
  static const String confirmLabel = 'I understand, delete';

  /// Secondary button label.
  static const String cancelLabel = 'Cancel';

  /// Title — locked verbatim per HB-004.
  static const String titleText = 'Delete your account?';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return AlertDialog(
      title: const Text(titleText),
      content: const Text(bodyText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(cancelLabel),
        ),
        FilledButton(
          // HB-004 spec + widget test contract: the destructive button's
          // *foreground* is theme.colorScheme.error. Background stays the
          // surface tint so the FilledButton reads as a strong CTA but
          // the colour-coded signal is in the label, matching the
          // existing "Sign out" coral pattern in this same screen.
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: errorColor,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(confirmLabel),
        ),
      ],
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/disclaimer_copy.dart';

/// Modal dialog presenting [DisclaimerCopy.full] with a single
/// "I understand" `FilledButton`.
///
/// Tapping the button writes `users/{uid}.insightsDisclaimerAcked = true`
/// via [DisclaimerRepository.ack] and pops the dialog. The Insights
/// screen calls [show] once on first visit, gated on the
/// [disclaimerAckStreamProvider] stream emitting `false`.
class DisclaimerAckDialog extends ConsumerWidget {
  const DisclaimerAckDialog({super.key, required this.userId});

  final String userId;

  /// Convenience opener — drops the dialog onto the navigator and
  /// returns when the user taps the button. Returns nothing — the
  /// caller observes [disclaimerAckStreamProvider] for the resulting
  /// state change rather than a dialog return value.
  static Future<void> show(BuildContext context, {required String userId}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DisclaimerAckDialog(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return AlertDialog(
      // The disclaimer body is ~250 chars; at 200% type on a small phone
      // the AlertDialog clips by default. Setting `scrollable: true`
      // wraps the content + actions in a SingleChildScrollView so the
      // dialog stays readable on every dynamic-type setting. The dialog
      // remains barrier-non-dismissible — only the "I understand"
      // button can pop it.
      scrollable: true,
      icon: Icon(
        Icons.medical_information_outlined,
        color: mb.textDim,
        size: 28,
      ),
      content: Text(
        DisclaimerCopy.full,
        style: MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.text),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            // Fire-and-forget: the rule is one-way, the stream provider
            // surfaces the resulting `true` to whoever observes it, and
            // the dialog has no "what happens on failure" affordance —
            // it would re-open the next time the user visits Insights,
            // which is the correct retry semantics. Failure logging
            // happens in the repo impl (PII-free `code` only).
            await ref.read(disclaimerRepositoryProvider).ack(userId: userId);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text(DisclaimerCopy.ackButton),
        ),
      ],
    );
  }
}

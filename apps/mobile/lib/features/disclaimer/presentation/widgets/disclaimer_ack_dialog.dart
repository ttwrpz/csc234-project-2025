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

  /// Convenience opener - drops the dialog onto the navigator and
  /// returns when the user taps the button. Returns nothing - the
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
      // `scrollable: true` keeps the body + actions readable at 200%
      // dynamic type on a small phone. Barrier-non-dismissible is set
      // by the launcher in [show] - only the "I understand" button can
      // pop the dialog.
      scrollable: true,
      backgroundColor: mb.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
      ),
      icon: Icon(
        Icons.medical_information_outlined,
        color: mb.textDim,
        size: 32,
      ),
      title: Text(
        'A note about MoodBloom',
        style: MbFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        DisclaimerCopy.full,
        style: MbFonts.nunito(fontSize: 14, height: 1.55, color: mb.text),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.lg,
        0,
        MoodBloomSpacing.lg,
        MoodBloomSpacing.md,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: MbPrimaryButton(
            label: DisclaimerCopy.ackButton,
            onPressed: () async {
              // Fire-and-forget: the rule is one-way, the stream
              // provider surfaces the resulting `true` to whoever
              // observes it, and the dialog has no "what happens on
              // failure" affordance - it would re-open the next time
              // the user visits Insights, which is the correct retry
              // semantics. Failure logging happens in the repo impl
              // (PII-free `code` only).
              await ref.read(disclaimerRepositoryProvider).ack(userId: userId);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

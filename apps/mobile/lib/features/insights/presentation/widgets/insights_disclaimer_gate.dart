import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../disclaimer/presentation/widgets/disclaimer_ack_dialog.dart';
import '../controllers/insights_controller.dart';

/// Listener widget that schedules the [DisclaimerAckDialog] the first
/// time the gate transitions to [InsightsGateState.disclaimerRequired]
/// after the screen mounts.
///
/// Idempotent via a session-scoped flag — the dialog opens at most once
/// per mount, so a slow ack write does not re-show the dialog mid-write.
/// The Insights chart stays hidden by the gate's `disclaimerRequired`
/// branch, so even if the dialog is dismissed somehow the data path
/// remains gated.
class InsightsDisclaimerGate extends ConsumerStatefulWidget {
  const InsightsDisclaimerGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InsightsDisclaimerGate> createState() =>
      _InsightsDisclaimerGateState();
}

class _InsightsDisclaimerGateState
    extends ConsumerState<InsightsDisclaimerGate> {
  bool _dialogShownThisMount = false;

  @override
  Widget build(BuildContext context) {
    // Listen — not watch — so transitioning into `disclaimerRequired`
    // schedules the dialog without rebuilding this widget on every
    // gate emission.
    ref.listen<InsightsGateState>(insightsGateProvider, (previous, next) {
      if (next == InsightsGateState.disclaimerRequired) {
        _maybeShow();
      }
    });
    // Cover the cold-start case: if the gate is already
    // `disclaimerRequired` on the FIRST build (which is the common
    // first-time-on-screen path), schedule the dialog after the frame
    // commits so the modal is parented under the screen's Navigator.
    final initial = ref.read(insightsGateProvider);
    if (initial == InsightsGateState.disclaimerRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShow();
      });
    }
    return widget.child;
  }

  void _maybeShow() {
    if (_dialogShownThisMount) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    _dialogShownThisMount = true;
    // `unawaited` is fine — DisclaimerAckDialog drives the ack state
    // change via the stream, not via the dialog return value.
    DisclaimerAckDialog.show(context, userId: user.uid).whenComplete(() {
      // Allow a future re-mount (e.g. after navigating away and back
      // before ack lands) to retry the dialog. Within a single mount
      // we still guard against duplicate opens via the flag above.
      if (!mounted) return;
      _dialogShownThisMount = false;
    });
  }
}

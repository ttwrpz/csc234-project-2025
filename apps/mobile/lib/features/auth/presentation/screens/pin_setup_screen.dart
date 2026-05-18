import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../widgets/pin_keypad.dart';

/// PIN setup screen.
///
/// Two-pass entry: first pass collects the new PIN, second pass
/// confirms. On mismatch the keypad clears and prompts again; on
/// match the use case writes `users/{uid}/security/pin` and the
/// screen calls [onSuccess].
///
/// The screen is decoupled from routing — it accepts an [onSuccess]
/// callback so the caller (the privacy setup flow OR the future Change
/// PIN flow) can decide what to do next.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({
    super.key,
    required this.userId,
    required this.onSuccess,
    this.onCancel,
  });

  final String userId;

  /// Fired after a successful write. The screen does NOT navigate;
  /// the caller (typically the privacy setup flow) advances or pops.
  final VoidCallback onSuccess;

  /// Optional handler for the cancel affordance (system back / explicit
  /// "Cancel" button). The setup flow should revert the PRIVACY toggle
  /// when cancelled, hence why this is a callback rather than a built-in.
  final VoidCallback? onCancel;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  /// Two-pass state. `_firstPin` is null while collecting the initial
  /// entry; once set, the keypad is in "confirm" mode.
  String? _firstPin;
  String? _error;
  bool _busy = false;

  final PinKeypadController _keypadController = PinKeypadController();

  Future<void> _onPinEntered(String pin) async {
    if (_busy) return;

    if (_firstPin == null) {
      // First pass — accept and ask for confirmation.
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      _keypadController.clear();
      return;
    }

    // Second pass — submit through the use case.
    setState(() => _busy = true);
    final useCase = ref.read(setupPinUseCaseProvider);
    final result = await useCase(
      userId: widget.userId,
      firstEntry: _firstPin!,
      confirmEntry: pin,
    );
    if (!mounted) return;
    result.fold(
      ok: (_) {
        setState(() => _busy = false);
        widget.onSuccess();
      },
      err: (failure) {
        // Mismatch → restart from the first-pass entry so the user
        // does both passes again. Other failures (storage, format)
        // keep the confirm pass so the user re-types confirmation.
        setState(() {
          _busy = false;
          _error = failure.message;
          if (failure.isMismatch) _firstPin = null;
        });
        _keypadController.clear();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isConfirmPass = _firstPin != null;
    final title = isConfirmPass ? 'Confirm your PIN' : 'Set a 6-digit PIN';
    final subtitle = isConfirmPass
        ? 'Enter the same 6 digits again to confirm.'
        : "PIN is the fallback when biometric isn’t available — for "
              'example on the web, or if your device’s fingerprint stops working.';

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: const Text('Privacy lock'),
        backgroundColor: mb.bg,
        leading: widget.onCancel == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
                tooltip: 'Cancel',
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: MbFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.5,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: PinKeypad(
                    controller: _keypadController,
                    enabled: !_busy,
                    onComplete: _onPinEntered,
                    errorText: _error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

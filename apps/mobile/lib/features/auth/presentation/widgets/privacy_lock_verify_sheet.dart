import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities/biometric_capability.dart';
import 'adaptive_modal.dart';
import 'pin_keypad.dart';

/// Confirmation gate shown before a sensitive change (currently: turning
/// OFF Privacy Lock). Verifies the user with biometric (when available +
/// opted in) and/or their PIN, mirroring the cold-boot unlock screen, then
/// pops `true` on success.
///
/// A found or borrowed phone that is already unlocked must not be able to
/// silently disable the lock - this re-checks the owner first.
class PrivacyLockVerifySheet extends ConsumerStatefulWidget {
  const PrivacyLockVerifySheet._({required this.showHandle});

  /// Draws the bottom-sheet drag handle. False in dialog (wide) mode.
  final bool showHandle;

  /// Presents the surface - a centred dialog on tablet/desktop, a bottom
  /// sheet on phones. Returns `true` only when the user verified.
  static Future<bool> show(BuildContext context) async {
    final showHandle = !isWideViewport(context);
    final result = await showAdaptiveModal<bool>(
      context,
      child: PrivacyLockVerifySheet._(showHandle: showHandle),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PrivacyLockVerifySheet> createState() =>
      _PrivacyLockVerifySheetState();
}

class _PrivacyLockVerifySheetState
    extends ConsumerState<PrivacyLockVerifySheet> {
  final PinKeypadController _keypadController = PinKeypadController();
  bool _busy = false;
  bool _biometricTried = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  bool _hasBiometric(BiometricCapability cap) =>
      cap.isAvailable && cap.hasEnrolledBiometrics && cap.userOptedIn;

  Future<void> _tryBiometric() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap == null || !_hasBiometric(cap)) return;
    setState(() => _busy = true);
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)(
      reason: 'Confirm to turn off Privacy Lock',
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _succeed(),
      // Declined / failed biometric: fall through to the PIN keypad.
      err: (_) => setState(() => _busy = false),
    );
  }

  Future<void> _onPinComplete(String digits) async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      setState(() => _error = 'Sign in first.');
      _keypadController.clear();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(verifyPinUseCaseProvider)(
      userId: user.uid,
      pinDigits: digits,
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _succeed(),
      err: (failure) {
        setState(() {
          _busy = false;
          _error = failure.message;
        });
        _keypadController.clear();
      },
    );
  }

  void _succeed() {
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    // The bg + shape come from showAdaptiveModal; this widget renders only
    // the content so it works identically inside a sheet or a dialog.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHandle) ...[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mb.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            "Confirm it's you",
            style: MbFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your PIN to turn off Privacy Lock.',
            textAlign: TextAlign.center,
            style: MbFonts.nunito(fontSize: 14, color: mb.textDim),
          ),
          const SizedBox(height: 16),
          PinKeypad(
            controller: _keypadController,
            enabled: !_busy,
            onComplete: _onPinComplete,
            errorText: _error,
            // Shares a scroll view with the Cancel button below.
            autofocusKeyboard: false,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

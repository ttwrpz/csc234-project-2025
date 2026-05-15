import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/history_unlocked_this_session_provider.dart';
import '../../data/providers.dart';
import '../../domain/entities/biometric_capability.dart';
import '../../domain/entities/pin_verify_failure.dart';
import '../widgets/pin_keypad.dart';

/// `/unlock-history` screen — the History privacy gate's verification
/// surface (ADR-0013 Decision C §4).
///
/// Flow:
///   1. On mount, if the device has a usable biometric AND the user
///      has opted into biometric, fire the OS biometric prompt.
///      Successful biometric → unlock + return to `?returnTo=...`.
///   2. Always show the PIN keypad fallback. Successful PIN → unlock
///      + return to `?returnTo=...`.
///
/// `returnTo` defaults to `/history` when absent so a direct visit to
/// `/unlock-history` lands on the History list after unlock.
class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  bool _busy = false;
  String? _errorText;
  DateTime? _lockedUntil;
  bool _biometricTried = false;

  final PinKeypadController _keypadController = PinKeypadController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  String get _returnPath => widget.returnTo ?? '/history';

  Future<void> _tryBiometric() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final capabilityAsync = ref.read(biometricCapabilityProvider);
    final cap = capabilityAsync.value;
    if (cap == null || !_hasBiometric(cap)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)(
      reason: 'Unlock your journal',
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _onUnlocked(),
      err: (_) {
        // Don't surface the biometric failure as an error in the PIN
        // panel — the user may have just declined biometric and now
        // wants to type their PIN. Silently fall through.
        setState(() => _busy = false);
      },
    );
  }

  bool _hasBiometric(BiometricCapability cap) =>
      cap.isAvailable && cap.hasEnrolledBiometrics && cap.userOptedIn;

  void _onUnlocked() {
    ref.read(historyUnlockedThisSessionProvider.notifier).unlock();
    if (mounted) context.go(_returnPath);
  }

  Future<void> _onPinComplete(String digits) async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      setState(() => _errorText = 'Sign in first to unlock your journal.');
      _keypadController.clear();
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await ref.read(verifyPinUseCaseProvider)(
      userId: user.uid,
      pinDigits: digits,
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _onUnlocked(),
      err: (failure) {
        setState(() {
          _busy = false;
          _errorText = _messageFor(failure);
          _lockedUntil = _lockedUntilFrom(failure);
        });
        _keypadController.clear();
      },
    );
  }

  String _messageFor(PinVerifyFailure failure) => failure.message;

  DateTime? _lockedUntilFrom(PinVerifyFailure failure) => failure.lockedUntil;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final lockedRemaining = _lockedUntil != null
        ? _lockedUntil!.difference(DateTime.now().toUtc())
        : Duration.zero;
    final isLocked = lockedRemaining > Duration.zero;

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: const Text('Privacy lock'),
        backgroundColor: mb.bg,
        // No back button — the user must either unlock or sign out
        // from the home tab. We don't want a stuck-on-the-gate state
        // where back lands at /history and the redirect fires again.
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unlock your journal',
                style: MbFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 6-digit PIN, or use biometric if it’s '
                'available on this device.',
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.5,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isLocked)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Too many tries. Please wait '
                    '${lockedRemaining.inSeconds + 1}s.',
                    style: MbFonts.nunito(
                      fontSize: 13,
                      color: MoodBloomColors.coralText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: Center(
                  child: PinKeypad(
                    controller: _keypadController,
                    enabled: !_busy && !isLocked,
                    onComplete: _onPinComplete,
                    errorText: _errorText,
                  ),
                ),
              ),
              if (_canRetryBiometric())
                Center(
                  child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () {
                            _biometricTried = false;
                            _tryBiometric();
                          },
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use biometric instead'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canRetryBiometric() {
    final cap = ref.read(biometricCapabilityProvider).value;
    return cap != null && _hasBiometric(cap);
  }
}

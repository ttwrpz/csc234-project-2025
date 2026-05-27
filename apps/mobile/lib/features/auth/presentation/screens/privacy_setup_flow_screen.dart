import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/entities/biometric_capability.dart';
import 'pin_setup_screen.dart';

/// `/privacy/setup` — the first-time setup orchestration screen for
/// the History privacy gate.
///
/// Sequences three steps:
///   - Biometric (skipped when biometric isn't available): verify the
///     user's existing biometric so we have an immediate test that they
///     can unlock with the same factor the History gate will require.
///   - PIN (always): two-pass PIN setup via [PinSetupScreen].
///   - Confirmation: "Privacy lock is on." card with a single "Done"
///     button that pops back to Settings.
///
/// Cancellation at any step rewinds the PRIVACY toggle to OFF —
/// callers should only flip the toggle ON once this screen returns
/// `true` via `context.pop(true)`.
class PrivacySetupFlowScreen extends ConsumerStatefulWidget {
  const PrivacySetupFlowScreen({super.key});

  @override
  ConsumerState<PrivacySetupFlowScreen> createState() =>
      _PrivacySetupFlowScreenState();
}

enum _Step { biometric, pin, done }

class _PrivacySetupFlowScreenState
    extends ConsumerState<PrivacySetupFlowScreen> {
  _Step _step = _Step.biometric;
  bool _biometricChecked = false;

  @override
  void initState() {
    super.initState();
    // Skip the biometric step immediately if biometric isn't available
    // on this device.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSkipBiometric());
  }

  void _maybeSkipBiometric() {
    if (_biometricChecked) return;
    _biometricChecked = true;
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap == null) return;
    if (!_hasBiometric(cap)) {
      setState(() => _step = _Step.pin);
    }
  }

  bool _hasBiometric(BiometricCapability cap) =>
      cap.isAvailable && cap.hasEnrolledBiometrics;

  Future<void> _runBiometricCheck() async {
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)(
      reason: 'Verify your fingerprint to set up Privacy Lock',
    );
    if (!mounted) return;
    await result.fold(
      ok: (_) async {
        // Privacy Lock setup is the single source of truth for
        // opting into biometric — when the user confirms their
        // biometric here, persist the opt-in so the unlock screen
        // fires the OS prompt on future cold boots. The
        // BiometricCapability provider is invalidated so dependent
        // widgets (the Privacy Lock settings tile subtitle) re-read
        // the new userOptedIn value.
        await ref.read(setBiometricOptInUseCaseProvider)(true);
        ref.invalidate(biometricCapabilityProvider);
        if (!mounted) return;
        setState(() => _step = _Step.pin);
      },
      err: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification was cancelled.'),
          ),
        );
        context.pop(false);
      },
    );
  }

  void _onPinSetupSuccess() {
    setState(() => _step = _Step.done);
  }

  void _cancel() => context.pop(false);

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.biometric => _BiometricStep(
        onContinue: _runBiometricCheck,
        onCancel: _cancel,
      ),
      _Step.pin => _PinStep(onSuccess: _onPinSetupSuccess, onCancel: _cancel),
      _Step.done => _DoneStep(onDone: () => context.pop(true)),
    };
  }
}

class _BiometricStep extends StatelessWidget {
  const _BiometricStep({required this.onContinue, required this.onCancel});

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: const MbSectionLabel('PRIVACY LOCK'),
        backgroundColor: mb.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCancel,
          tooltip: 'Cancel',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.fingerprint, size: 56, color: mb.text),
              const SizedBox(height: 16),
              Text(
                'Verify your fingerprint',
                style: MbFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This is the same biometric you use to sign in. We use it '
                'to unlock your journal.',
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.5,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              MbPrimaryButton(label: 'Continue', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinStep extends ConsumerWidget {
  const _PinStep({required this.onSuccess, required this.onCancel});

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    if (user == null) {
      // The setup flow is unreachable when signed out. This branch is
      // defensive — if it fires we bail back to Settings rather than
      // render a half-state.
      WidgetsBinding.instance.addPostFrameCallback((_) => onCancel());
      return const SizedBox.shrink();
    }
    return PinSetupScreen(
      userId: user.uid,
      onSuccess: onSuccess,
      onCancel: onCancel,
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: const MbSectionLabel('PRIVACY LOCK'),
        backgroundColor: mb.bg,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 56, color: mb.text),
              const SizedBox(height: 16),
              Text(
                'Privacy lock is on',
                style: MbFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your journal will ask for biometric or PIN to open.',
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.5,
                  color: mb.textDim,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              MbPrimaryButton(label: 'Done', onPressed: onDone),
            ],
          ),
        ),
      ),
    );
  }
}

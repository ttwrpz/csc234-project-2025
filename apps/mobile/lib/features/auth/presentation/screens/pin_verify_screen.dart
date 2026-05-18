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
/// surface.
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

  /// True while the OS biometric dialog is up. The PIN keypad hides
  /// itself behind a "Verifying with biometric…" placeholder during
  /// this window so the user doesn't perceive a "double prompt" (PIN
  /// keypad visible behind the OS biometric overlay). Resets to false
  /// on biometric success/cancellation/failure.
  bool _biometricInProgress = false;

  final PinKeypadController _keypadController = PinKeypadController();

  @override
  void initState() {
    super.initState();
    // Synchronously pre-set `_biometricInProgress = true` when we
    // already know biometric will fire — this stops the PIN keypad
    // from flashing on the first frame before the post-frame callback
    // sets the flag. The capability provider is a `FutureProvider`,
    // but by the time the user lands on /unlock-history the value is
    // almost always cached, so `.value` returns the resolved record.
    // If it isn't cached yet the keypad shows briefly — acceptable
    // edge case, since the alternative is a perpetual placeholder for
    // users with no biometric at all.
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap != null && _hasBiometric(cap)) {
      _biometricInProgress = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defence-in-depth: if biometric was already verified this
      // session (cold-boot gate or any earlier verify), auto-unlock
      // and skip the screen entirely. The router redirect at
      // app/router.dart already catches this on the way in, but in
      // case a deep link lands us here directly we still short-
      // circuit. Same hardware verification — no need to prompt twice.
      if (ref.read(biometricUnlockedThisSessionProvider)) {
        _onUnlocked();
        return;
      }
      _tryBiometric();
    });
  }

  String get _returnPath => widget.returnTo ?? '/history';

  Future<void> _tryBiometric() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap == null || !_hasBiometric(cap)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _biometricInProgress = true;
    });
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
        setState(() {
          _busy = false;
          _biometricInProgress = false;
        });
      },
    );
  }

  bool _hasBiometric(BiometricCapability cap) =>
      cap.isAvailable && cap.hasEnrolledBiometrics && cap.userOptedIn;

  void _onUnlocked() {
    // Also flip the cold-boot biometric flag so the next router pass
    // does NOT redirect the user to /biometric-gate. Without this, the
    // flow was:
    //   1. Tap History → privacy-lock fires (biometricUnlocked=false)
    //   2. User unlocks via PIN or biometric on /unlock-history
    //   3. context.go('/history') → router redirect re-runs
    //   4. Cold-boot biometric gate fires (still biometricUnlocked=false)
    //   5. Second biometric prompt — the "double lock".
    // Both flags clear on sign-out (router.dart auth-state listener),
    // so the session-bind is still tight.
    ref.read(biometricUnlockedThisSessionProvider.notifier).state = true;
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

  /// Phone / tablet / desktop breakpoints — mirrored from `_AppShell`
  /// and `OnboardingScreen` so the privacy lock matches the rest of
  /// the app's responsive behaviour.
  static const double _tabletMin = 600;
  static const double _desktopMin = 900;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final lockedRemaining = _lockedUntil != null
        ? _lockedUntil!.difference(DateTime.now().toUtc())
        : Duration.zero;
    final isLocked = lockedRemaining > Duration.zero;

    // `ref.watch` (not `ref.read`) so the "Use biometric instead"
    // button appears as soon as the FutureProvider resolves, rather
    // than only after the first PIN completion forces a rebuild.
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final cap = capabilityAsync.value;
    final canUseBiometric =
        cap != null &&
        cap.isAvailable &&
        cap.hasEnrolledBiometrics &&
        cap.userOptedIn;

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        title: const Text('Privacy lock'),
        backgroundColor: mb.bg,
        // Back button so a user who misclicks into /history has an
        // escape hatch. Routes to /home (the only safe target — the
        // user can't go "back" because /unlock-history was a
        // redirect, not a push).
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to home',
          onPressed: _busy ? null : () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            // Cap content width on tablet + desktop so the keypad
            // doesn't span half a metre on a 1440 dp monitor. Phone
            // (<600) keeps the prior full-width treatment.
            final maxBodyWidth = w >= _desktopMin
                ? 640.0
                : (w >= _tabletMin ? 560.0 : double.infinity);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBodyWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    w >= _tabletMin ? 32 : 24,
                    8,
                    w >= _tabletMin ? 32 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Unlock your journal',
                        style: MbFonts.fraunces(
                          fontSize: w >= _desktopMin ? 28 : 22,
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
                              // Theme-aware destructive-text token —
                              // `coralText` is the light-theme binding
                              // (6.04:1 PASS on cream `mb.bg`) but fails
                              // dark AA at ~2.54:1, so prefer the
                              // MbColors extension so contrast works in
                              // both light + dark themes.
                              color:
                                  theme
                                      .extension<MbColors>()
                                      ?.destructiveText ??
                                  theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: Center(
                          // While the OS biometric dialog is on screen,
                          // hide the PIN keypad behind a quiet
                          // placeholder. The keypad reappears once
                          // biometric resolves — success routes away,
                          // cancel/failure falls back to PIN. Without
                          // this swap the keypad renders behind the OS
                          // dialog and reads as a second-prompt.
                          child: _biometricInProgress
                              ? _BiometricVerifyingPlaceholder(mb: mb)
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: PinKeypad(
                                    controller: _keypadController,
                                    enabled: !_busy && !isLocked,
                                    onComplete: _onPinComplete,
                                    errorText: _errorText,
                                  ),
                                ),
                        ),
                      ),
                      if (canUseBiometric)
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
          },
        ),
      ),
    );
  }
}

/// Renders a big fingerprint glyph + caption while the OS biometric
/// prompt is on screen. Replaces the PIN keypad during that window so
/// the user doesn't see a second affordance behind the OS dialog.
class _BiometricVerifyingPlaceholder extends StatelessWidget {
  const _BiometricVerifyingPlaceholder({required this.mb});

  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fingerprint, size: 72, color: mb.text),
        const SizedBox(height: 16),
        Text(
          'Verifying with biometric…',
          style: MbFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: mb.textDim,
          ),
        ),
      ],
    );
  }
}

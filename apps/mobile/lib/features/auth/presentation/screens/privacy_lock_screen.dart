import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/entities/biometric_capability.dart';
import '../../domain/entities/pin_verify_failure.dart';
import '../widgets/pin_keypad.dart';

/// `/privacy-lock` - the unified Privacy Lock verification screen.
///
/// Replaces the prior `BiometricGateScreen` (biometric-only cold-boot
/// gate) and `PinVerifyScreen` (biometric-first + PIN-fallback history
/// gate). One screen now serves the whole-app cold-boot gate: biometric
/// is the primary verification method when available, and PIN is the
/// mandatory fallback.
///
/// Flow:
///   1. On mount, if the device has a usable biometric AND the user has
///      opted into biometric, fire the OS biometric prompt. Successful
///      biometric → unlock + navigate to `?returnTo=...`.
///   2. Always show the PIN keypad fallback. Successful PIN → unlock +
///      navigate to `?returnTo=...`.
///   3. A "Sign out instead" affordance lives at the bottom so the
///      cold-boot user always has an exit hatch - there is no app shell
///      to "go back" to before unlock.
///
/// `returnTo` defaults to `/home` when absent: this is the cold-boot
/// gate, and `/home` is the canonical post-sign-in landing route. There
/// is no appbar back button - there is nowhere to back-navigate to
/// when this screen is the first frame after sign-in.
class PrivacyLockScreen extends ConsumerStatefulWidget {
  const PrivacyLockScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<PrivacyLockScreen> createState() => _PrivacyLockScreenState();
}

class _PrivacyLockScreenState extends ConsumerState<PrivacyLockScreen> {
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
    // already know biometric will fire - this stops the PIN keypad
    // from flashing on the first frame before the post-frame callback
    // sets the flag. By the time the user lands on /privacy-lock the
    // capability value is pre-resolved by `main.dart`, so `.value`
    // returns the resolved record on the first read.
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap != null && _hasBiometric(cap)) {
      _biometricInProgress = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defence-in-depth: if the session is already unlocked (deep
      // link landed us here despite the redirect having no work to
      // do), short-circuit and route to the destination. The router
      // redirect should catch this on the way in, but a stray push
      // could land here directly.
      if (ref.read(privacyLockUnlockedThisSessionProvider)) {
        _onUnlocked();
        return;
      }
      _tryBiometric();
    });
  }

  String get _returnPath => widget.returnTo ?? '/home';

  Future<void> _tryBiometric() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final cap = ref.read(biometricCapabilityProvider).value;
    if (cap == null || !_hasBiometric(cap)) {
      // No biometric on this device or user hasn't opted in - fall
      // straight through to the PIN keypad. Reset the in-progress
      // flag so the keypad is visible on first paint.
      if (mounted) setState(() => _biometricInProgress = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _biometricInProgress = true;
    });
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)(
      reason: 'Unlock MoodBloom',
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _onUnlocked(),
      err: (_) {
        // Don't surface the biometric failure as an error in the PIN
        // panel - the user may have just declined biometric and now
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
    ref.read(privacyLockUnlockedThisSessionProvider.notifier).state = true;
    if (mounted) context.go(_returnPath);
  }

  Future<void> _onPinComplete(String digits) async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      setState(() => _errorText = 'Sign in first to unlock MoodBloom.');
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

  /// "Use security key" tap handler - ADR-0014 Decision D. Runs the
  /// WebAuthn assertion ceremony; on success flips the session unlock
  /// flag exactly as the PIN happy-path does and navigates onwards. On
  /// failure surfaces a compact inline error (mirroring the biometric
  /// inline-error pattern), keeping the PIN keypad reachable as the
  /// fallback factor.
  Future<void> _onUseSecurityKey() async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      setState(() => _errorText = 'Sign in first to unlock MoodBloom.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await ref.read(verifyWebauthnUseCaseProvider)(
      userId: user.uid,
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _onUnlocked(),
      err: (failure) {
        setState(() {
          _busy = false;
          // userCanceled is silent - the user dismissed the prompt and
          // already knows. Anything else surfaces the failure message.
          _errorText = failure.isUserCanceled ? null : failure.message;
          _lockedUntil = failure.lockedUntil;
        });
      },
    );
  }

  /// Explicit exit affordance - signs out, clears the session-scoped
  /// unlock flag, and returns to /sign-in. The router's auth gate
  /// then drives the rest of the redirect chain.
  Future<void> _signOutInstead() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(signOutUseCaseProvider)();
    if (!mounted) return;
    ref.read(privacyLockUnlockedThisSessionProvider.notifier).state = false;
    context.go('/sign-in');
  }

  /// Phone / tablet / desktop breakpoints - mirrored from `_AppShell`
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

    // ADR-0014 Decision D - the "Use security key" affordance appears
    // when WebAuthn is reachable on this platform AND the user has
    // registered a credential. On native or pre-flag-flip builds the
    // available flag stays false and the button never shows.
    final webauthnAvailable = ref.watch(webauthnAvailableProvider);
    final webauthnCredential = ref.watch(webauthnCredentialProvider).value;
    final canUseSecurityKey = webauthnAvailable && webauthnCredential != null;

    return Scaffold(
      backgroundColor: mb.bg,
      // v1.6: no native AppBar - the prototype's PrivacyLockScreen
      // leads with a centered hero. The "Privacy lock" title moves
      // into the body as a small uppercase eyebrow above the warmer
      // "Welcome back" headline.
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
                    24,
                    w >= _tabletMin ? 32 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: MbSectionLabel('PRIVACY LOCK')),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back',
                        style: MbFonts.fraunces(
                          fontSize: w >= _desktopMin ? 28 : 24,
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
                              // Theme-aware destructive-text token -
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
                          // biometric resolves - success routes away,
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
                      if (canUseSecurityKey)
                        Center(
                          child: TextButton.icon(
                            onPressed: _busy ? null : _onUseSecurityKey,
                            icon: const Icon(Icons.key),
                            label: const Text('Use security key'),
                          ),
                        ),
                      // Cold-boot exit hatch - the unlock screen is the
                      // first frame after sign-in, so there's no app
                      // shell to back-navigate to. "Sign out instead"
                      // lets the user explicitly leave the locked state
                      // without being trapped. Mirrors the affordance
                      // from the prior `BiometricGateScreen`.
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: _busy ? null : _signOutInstead,
                          child: const Text('Sign out instead'),
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

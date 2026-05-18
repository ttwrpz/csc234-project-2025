import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import 'widgets/brand_mark.dart';

/// Cold-boot biometric gate. Triggers the OS prompt on mount; on success
/// flips [biometricUnlockedThisSessionProvider] to true and navigates to
/// `/home`.
///
/// On cancellation or failure the screen **stays here** with an inline
/// error message, a primary "Try again" button (re-runs the prompt),
/// and a secondary "Sign out instead" link (explicit exit). Auto-
/// ejecting to `/sign-in` after any failure — including the trivial
/// "user tapped cancel on the OS dialog" case — would surface as "the
/// app suddenly signs me out several seconds after I close the
/// biometric dialog." Letting the user drive the exit matches the
/// biometric re-auth UX of banking + health apps.
class BiometricGateScreen extends ConsumerStatefulWidget {
  const BiometricGateScreen({super.key});

  @override
  ConsumerState<BiometricGateScreen> createState() =>
      _BiometricGateScreenState();
}

class _BiometricGateScreenState extends ConsumerState<BiometricGateScreen> {
  /// Inline error surfaced under the body copy when a prompt cycle
  /// finishes with a failure. Null on first paint and after the user
  /// successfully verifies. Cleared by the next `_runPrompt` attempt.
  String? _errorMessage;

  /// True while the OS dialog is on screen. Disables both action
  /// buttons so a double-tap doesn't queue a second prompt under the
  /// first one (which on Android stacks and on iOS errors).
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Schedule onto the post-frame so the first frame paints the loading
    // spinner before the OS prompt appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrompt());
  }

  Future<void> _runPrompt() async {
    if (_busy) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _errorMessage = null;
      });
    }

    final usecase = ref.read(authenticateWithBiometricUseCaseProvider);
    final result = await usecase(reason: 'Verify your identity to continue');

    if (!mounted) return;

    result.fold(
      ok: (_) {
        ref.read(biometricUnlockedThisSessionProvider.notifier).state = true;
        context.go('/home');
      },
      err: (failure) {
        // Park on this screen so the user can retry or explicitly sign
        // out — do NOT auto-eject to /sign-in. Surface the failure
        // message inline; for the cancellation variant the message
        // reads "Biometric verification was cancelled." which is fine
        // info without being shaming.
        setState(() {
          _busy = false;
          _errorMessage = failure.message;
        });
      },
    );
  }

  /// Explicit exit affordance — signs out, clears the session-scoped
  /// biometric flag, and returns to /sign-in. The router's auth gate
  /// will then drive the rest of the redirect chain.
  Future<void> _signOutInstead() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(signOutUseCaseProvider)();
    if (!mounted) return;
    ref.read(biometricUnlockedThisSessionProvider.notifier).state = false;
    context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final errorMessage = _errorMessage;
    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Semantics(
              liveRegion: true,
              child: MbCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 18),
                    Text(
                      'Verify your identity',
                      style: MbFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: mb.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your fingerprint or face to continue.',
                      style: MbFonts.nunito(
                        fontSize: 14,
                        height: 1.5,
                        color: mb.textDim,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: MbFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    MbPrimaryButton(
                      label: 'Try again',
                      leading: const Icon(
                        Icons.fingerprint,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _busy ? null : _runPrompt,
                    ),
                    const SizedBox(height: 8),
                    MbGhostButton(
                      label: 'Sign out instead',
                      onPressed: _busy ? null : _signOutInstead,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

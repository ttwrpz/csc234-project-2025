import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import 'widgets/brand_mark.dart';

/// Cold-boot biometric gate. Triggers the OS prompt on mount; on success
/// flips [biometricUnlockedThisSessionProvider] to true and navigates to
/// `/home`; on cancellation or failure signs the user out and returns them
/// to `/sign-in` with a compassionate snackbar.
class BiometricGateScreen extends ConsumerStatefulWidget {
  const BiometricGateScreen({super.key});

  @override
  ConsumerState<BiometricGateScreen> createState() =>
      _BiometricGateScreenState();
}

class _BiometricGateScreenState extends ConsumerState<BiometricGateScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Schedule onto the post-frame so the first frame paints the loading
    // spinner before the OS prompt appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrompt());
  }

  Future<void> _runPrompt() async {
    if (_started) return;
    _started = true;

    final usecase = ref.read(authenticateWithBiometricUseCaseProvider);
    final result = await usecase(reason: 'Verify your identity to continue');

    if (!mounted) return;

    result.fold(
      ok: (_) {
        ref.read(biometricUnlockedThisSessionProvider.notifier).state = true;
        context.go('/home');
      },
      err: (_) async {
        // Cancellation OR hardware failure — both treat the same way: sign
        // out so the user re-enters credentials, and show a non-shaming
        // snackbar.
        await ref.read(signOutUseCaseProvider)();
        ref.read(biometricUnlockedThisSessionProvider.notifier).state = false;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t verify — please sign in again.'),
          ),
        );
        context.go('/sign-in');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
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
                    const SizedBox(height: 20),
                    MbPrimaryButton(
                      label: 'Try again',
                      leading: const Icon(
                        Icons.fingerprint,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _started = false;
                        _runPrompt();
                      },
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

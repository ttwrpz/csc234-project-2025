import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MoodBloomSpacing.xl),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint, size: 64),
                  const SizedBox(height: MoodBloomSpacing.lg),
                  Text(
                    'Verify your identity',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: MoodBloomSpacing.sm),
                  Text(
                    'Use your fingerprint or face to continue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

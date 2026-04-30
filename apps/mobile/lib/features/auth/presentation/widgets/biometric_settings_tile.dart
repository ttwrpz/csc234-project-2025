import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities/biometric_capability.dart';

/// Switch tile for the biometric opt-in. Lives inside the settings screen.
///
/// Behaviour:
/// - If hardware is unavailable or no biometric is enrolled, the tile is
///   visually disabled with explanatory subtitle copy.
/// - When the user flips the switch ON, we run the OS prompt once to confirm
///   they can actually authenticate. If they cancel, we revert the toggle
///   so they're never trapped in an opt-in they can't undo.
/// - Flipping OFF is unconditional and immediate.
class BiometricSettingsTile extends ConsumerWidget {
  const BiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(biometricCapabilityProvider);

    return capabilityAsync.when(
      loading: () => const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Use biometric to unlock'),
        subtitle: LinearProgressIndicator(),
      ),
      error: (_, _) => const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Use biometric to unlock'),
        subtitle: Text('Biometric is not available on this device.'),
        enabled: false,
      ),
      data: (capability) => _Tile(capability: capability),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.capability});
  final BiometricCapability capability;

  bool get _isHardwareReady =>
      capability.isAvailable && capability.hasEnrolledBiometrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = _isHardwareReady
        ? null
        : const Text(
            'Add a fingerprint or face on your device to enable this.',
          );

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: const Text('Use biometric to unlock'),
      subtitle: subtitle,
      value: _isHardwareReady && capability.userOptedIn,
      onChanged: _isHardwareReady ? (v) => _onToggle(context, ref, v) : null,
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final setOptIn = ref.read(setBiometricOptInUseCaseProvider);

    if (!value) {
      await setOptIn(false);
      ref.invalidate(biometricCapabilityProvider);
      return;
    }

    // Persist opt-in first so the OS prompt sees a consistent state, then
    // confirm with a live biometric check.
    await setOptIn(true);
    final authenticate = ref.read(authenticateWithBiometricUseCaseProvider);
    final result = await authenticate(
      reason: 'Confirm biometric to enable unlock',
    );

    final ok = result.fold(ok: (_) => true, err: (_) => false);
    if (!ok) {
      // Revert — the user cancelled or the prompt failed.
      await setOptIn(false);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Biometric not enabled.')));
      }
    }
    ref.invalidate(biometricCapabilityProvider);
  }
}

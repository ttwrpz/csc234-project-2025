import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

/// Unified Privacy Lock settings tile — replaces the prior
/// `BiometricSettingsTile` + `PrivacySettingsTile` pair.
///
/// One switch with a subtitle that adapts to device + opt-in state:
///   - Hardware absent  → "Add a fingerprint or face on your device
///                          for faster unlock — PIN will be the only
///                          unlock method."
///   - Hardware present, disabled → "Use biometric or PIN to unlock
///                                   the app."
///   - Enabled, biometric present → "Your app is protected by biometric
///                                   or PIN."
///   - Enabled, no biometric      → "PIN is the only unlock method on
///                                   this device."
///   - Signed out → "Sign in first to set up Privacy Lock."
///
/// Toggling ON pushes `/privacy/setup` modal. The setup flow handles
/// PIN setup AND bundles biometric opt-in in one place (single source
/// of truth — see [privacy_setup_flow_screen.dart]).
///
/// Toggling OFF persists the opt-out, resets biometric opt-in (so the
/// next enable goes through a fresh prompt), and invalidates the
/// stored PIN hash so re-enabling forces a fresh setup rather than
/// silently reusing the prior PIN.
///
/// "Change PIN" tile appears below the switch when enabled.
class PrivacyLockSettingsTile extends ConsumerWidget {
  const PrivacyLockSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    if (user == null) {
      return const _SignedOutTile();
    }

    final enabled = ref.watch(privacyLockEnabledProvider);
    final capabilityAsync = ref.watch(biometricCapabilityProvider);

    final hasBiometric = capabilityAsync.maybeWhen(
      data: (cap) => cap.isAvailable && cap.hasEnrolledBiometrics,
      orElse: () => false,
    );

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Privacy Lock'),
          subtitle: Text(_subtitleFor(enabled, hasBiometric)),
          value: enabled,
          onChanged: (next) => _onToggle(context, ref, next, user.uid),
        ),
        if (enabled) const _ChangePinTile(),
      ],
    );
  }

  static String _subtitleFor(bool enabled, bool hasBiometric) {
    if (!enabled) {
      if (!hasBiometric) {
        return 'Set up a PIN to enable. Add a fingerprint or face on '
            'your device for faster unlock.';
      }
      return 'Use biometric or PIN to unlock the app.';
    }
    if (!hasBiometric) {
      return 'PIN is the only unlock method on this device.';
    }
    return 'Your app is protected by biometric or PIN.';
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool next,
    String userId,
  ) async {
    if (next) {
      // Push the setup flow as a modal route. The flow pops with
      // `true` on success, `false` on cancel. We only flip the
      // persisted opt-in on `true` so a cancelled flow leaves the
      // switch OFF (and any partial state cleared). The setup flow
      // itself bundles biometric opt-in when hardware is present.
      final completed = await context.push<bool>('/privacy/setup');
      if (!context.mounted) return;
      if (completed == true) {
        await ref.read(privacyLockEnabledProvider.notifier).set(true);
      }
      return;
    }

    // Flipping OFF: persist the opt-out, reset biometric opt-in (so
    // biometric + Privacy Lock disable together), and invalidate the
    // stored PIN hash so a re-enable goes through a full setup flow
    // rather than silently reusing the prior PIN. The Firestore rule
    // denies client-side delete; remove() writes a random
    // unrecoverable hash in place.
    await ref.read(privacyLockEnabledProvider.notifier).set(false);
    await ref.read(setBiometricOptInUseCaseProvider)(false);
    ref.invalidate(biometricCapabilityProvider);
    final result = await ref.read(removePinUseCaseProvider)(userId: userId);
    if (!context.mounted) return;
    result.fold(
      ok: (_) => ref.invalidate(pinIsSetProvider),
      err: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Privacy Lock turned off - your PIN will be removed on '
              'next sync.',
            ),
          ),
        );
      },
    );
  }
}

class _SignedOutTile extends StatelessWidget {
  const _SignedOutTile();

  @override
  Widget build(BuildContext context) {
    return const SwitchListTile(
      secondary: Icon(Icons.lock_outline),
      title: Text('Privacy Lock'),
      subtitle: Text('Sign in first to set up Privacy Lock.'),
      value: false,
      onChanged: null,
    );
  }
}

class _ChangePinTile extends StatelessWidget {
  const _ChangePinTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.password_outlined),
      title: const Text('Change PIN'),
      subtitle: const Text('Replace your existing PIN.'),
      trailing: const Icon(Icons.chevron_right),
      // The affordance re-uses the setup flow (which overwrites the
      // existing hash); a dedicated current-PIN + new-PIN screen is a
      // future enhancement.
      onTap: () => context.push('/privacy/setup'),
    );
  }
}

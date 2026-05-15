import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

/// PRIVACY card tiles (ADR-0013 Decision F).
///
/// Renders the master "Require unlock to view history" switch plus
/// the conditional "Set up PIN" / "Change PIN" tiles below it. All
/// five states from Decision F are covered:
///   1. OFF, no PIN, no biometric — switch enabled, no PIN tiles.
///   2. OFF, no PIN, biometric present — switch enabled, no PIN tiles.
///   3. ON, PIN set, biometric present — switch ON, "Change PIN" tile.
///   4. ON, PIN set, no biometric — switch ON, "Change PIN" tile,
///      subtitle reads "PIN is the only unlock method on this device."
///   5. ON requested but no PIN set — reverted via snackbar (handled by
///      the flow router; this widget never lands in that state).
///
/// Signed-out users see the switch disabled with the
/// "Sign in first to set up a privacy lock." subtitle — defence in
/// depth for ADR-0013 Open Follow-up #4 (the parent Settings screen
/// already gates the PRIVACY section on `user != null`).
class PrivacySettingsTile extends ConsumerWidget {
  const PrivacySettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    if (user == null) {
      return const _SignedOutTile();
    }

    final enabled = ref.watch(privacyLockEnabledProvider);
    final pinIsSetAsync = ref.watch(pinIsSetProvider);
    final capabilityAsync = ref.watch(biometricCapabilityProvider);

    final hasBiometric = capabilityAsync.maybeWhen(
      data: (cap) => cap.isAvailable && cap.hasEnrolledBiometrics,
      orElse: () => false,
    );

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Require unlock to view history'),
          subtitle: Text(_subtitleFor(enabled, hasBiometric)),
          value: enabled,
          onChanged: (next) => _onToggle(context, ref, next, user.uid),
        ),
        if (enabled)
          pinIsSetAsync.when(
            loading: () => const ListTile(
              leading: Icon(Icons.password_outlined),
              title: Text('Set up PIN'),
              subtitle: LinearProgressIndicator(),
            ),
            error: (_, _) => const ListTile(
              leading: Icon(Icons.password_outlined),
              title: Text('Set up PIN'),
              subtitle: Text('Could not check PIN status.'),
            ),
            data: (pinSet) => pinSet
                ? const _ChangePinTile()
                : _SetupPinTile(userId: user.uid),
          ),
      ],
    );
  }

  static String _subtitleFor(bool enabled, bool hasBiometric) {
    if (!enabled) {
      return "Ask for your fingerprint or PIN before showing the journal.";
    }
    if (!hasBiometric) {
      return 'PIN is the only unlock method on this device.';
    }
    return 'Your journal is protected by biometric or PIN.';
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool next,
    String userId,
  ) async {
    if (next) {
      // Decision G — push the setup flow as a modal route. The flow
      // pops with `true` on success, `false` on cancel. We only flip
      // the persisted opt-in on `true` so a cancelled flow leaves
      // the switch OFF (and any partial state cleared).
      final completed = await context.push<bool>('/privacy/setup');
      if (!context.mounted) return;
      if (completed == true) {
        await ref.read(privacyLockEnabledProvider.notifier).set(true);
      }
      return;
    }

    // Flipping OFF: persist the opt-out AND invalidate the stored PIN
    // hash so a re-enable goes through a full setup flow rather than
    // silently reusing the prior PIN. Per ADR-0013 Decision E §3 the
    // Firestore rule denies client-side delete; remove() writes a
    // random unrecoverable hash in place.
    await ref.read(privacyLockEnabledProvider.notifier).set(false);
    final result = await ref.read(removePinUseCaseProvider)(userId: userId);
    if (!context.mounted) return;
    result.fold(
      ok: (_) => ref.invalidate(pinIsSetProvider),
      err: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Privacy lock turned off — your PIN will be removed on '
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
      title: Text('Require unlock to view history'),
      subtitle: Text('Sign in first to set up a privacy lock.'),
      value: false,
      onChanged: null,
    );
  }
}

class _SetupPinTile extends StatelessWidget {
  const _SetupPinTile({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.password_outlined),
      title: const Text('Set up PIN'),
      subtitle: const Text(
        "PIN is the fallback when biometric isn’t available.",
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/privacy/setup'),
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
      // ADR-0013 "If you must cut for time" tier 2: Change-PIN UI is
      // first on the chopping block. v1.5 ships the affordance but
      // re-uses the setup flow (which overwrites the existing hash);
      // a dedicated current-PIN + new-PIN screen ships in v1.6.
      onTap: () => context.push('/privacy/setup'),
    );
  }
}

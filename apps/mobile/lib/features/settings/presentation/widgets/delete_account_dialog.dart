import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../auth/domain/auth_credentials.dart';
import '../../../auth/domain/auth_failure.dart';

/// Two-step destructive confirmation dialog wired into Settings →
/// Account → "Delete account". Step 1 confirms intent; step 2
/// reauthenticates the user and triggers the use case. Lives as a
/// standalone widget so it can be unit-tested without the rest of the
/// Settings screen.
///
/// On success: the use case's `signOut()` emits a `null` auth state,
/// which the router's existing `currentUserStreamProvider` listener
/// handles by redirecting to the sign-in route.
///
/// Non-password providers (Google, Apple): the codebase ships
/// email/password sign-in plus Google. The dialog handles the
/// password path natively; for Google-signed users we surface a "Use
/// Google to confirm" affordance that calls the existing OAuth reauth
/// path (`AuthCredentials.google`) through the repository.
/// Biometric-only users without a known password fall through to the
/// Google branch (their account always has at least one provider).
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  /// Helper that opens the dialog from a button tap. Returns `true` if
  /// deletion completed; `false` (or `null`) otherwise. Callers should
  /// generally not need to inspect the return value — the auth-state
  /// stream takes care of the navigation side-effect.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

enum _Step { confirmIntent, reauthAndConfirm }

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  static const int _minPasswordChars = 6;

  _Step _step = _Step.confirmIntent;
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;
  String? _inlineError;
  String? _passwordChars; // mirrors controller, drives the enabled state.

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _passwordChars = _passwordController.text;
        // Clear stale wrong-password / network errors once the user
        // edits the field again.
        _inlineError = null;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.confirmIntent => _buildIntentStep(context),
      _Step.reauthAndConfirm => _buildReauthStep(context),
    };
  }

  Widget _buildIntentStep(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account, all mood entries, gardens, '
        'and uploads. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => setState(() => _step = _Step.reauthAndConfirm),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildReauthStep(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled =
        !_submitting && (_passwordChars?.length ?? 0) >= _minPasswordChars;
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('For your security, please re-enter your password.'),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _inlineError,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: enabled ? (_) => _submit() : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: enabled ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete forever'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _inlineError = null;
    });
    // Resolve the email from the currently signed-in user — the
    // PasswordCredentials envelope needs both halves, but we only
    // ask the user for the password (asking them to retype their own
    // email would be friction without a security gain).
    final email = ref.read(authRepositoryProvider).currentUser?.email;
    final messenger = ScaffoldMessenger.of(context);
    if (email == null) {
      // Defensive: if we somehow got here without a signed-in user,
      // close the dialog rather than calling the use case. The
      // auth-state stream should have redirected away from Settings
      // before we got this far.
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    final useCase = ref.read(deleteAccountUseCaseProvider);
    final result = await useCase(
      reauth: AuthCredentials.password(
        email: email,
        password: _passwordController.text,
      ),
    );

    if (!mounted) return;

    switch (result) {
      case Ok<void, AuthFailure>():
        // signOut already triggered the auth-state listener; close
        // the dialog so the router redirect can render the sign-in
        // route on top of a clean Settings frame.
        Navigator.of(context).pop(true);
      case Err<void, AuthFailure>(:final failure):
        if (_isWrongPassword(failure)) {
          setState(() {
            _submitting = false;
            _inlineError = 'Password did not match. Try again.';
          });
        } else if (_isNetwork(failure)) {
          Navigator.of(context).pop(false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Could not reach our servers. Your account is unchanged.',
              ),
            ),
          );
        } else {
          // Generic fallback — surface inline so the user can retry.
          setState(() {
            _submitting = false;
            _inlineError = failure.message;
          });
        }
    }
  }

  // Sentinel comparisons via `identical` exploit the `const factory`
  // contract on AuthFailure — every variant constructed via the
  // factory is the same instance. Keeps the dialog free of private
  // class imports from the failure module.
  static bool _isWrongPassword(AuthFailure failure) =>
      identical(failure, const AuthFailure.wrongPassword());
  static bool _isNetwork(AuthFailure failure) =>
      identical(failure, const AuthFailure.network());
}

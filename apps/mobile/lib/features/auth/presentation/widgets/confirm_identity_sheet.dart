import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/auth_credentials.dart';
import '../../domain/entities/biometric_capability.dart';
import 'adaptive_modal.dart';
import 'pin_keypad.dart';

/// Step-up re-authentication modal. Confirms the user's identity with ANY
/// one of their available factors before a sensitive action (e.g. removing
/// a security key). Pops `true` on the first successful factor, `false`
/// (or null) on cancel.
///
/// Factors offered:
///   - PIN keypad (always - the PIN is the universal fallback; WebAuthn
///     registration requires it, so any user with a key also has a PIN);
///   - biometric, when the device has an enrolled, opted-in biometric;
///   - security key, when WebAuthn is available + a credential is
///     registered;
///   - account password, via an expandable field (reauthenticate).
///
/// Reuses the same verify use cases as the Privacy Lock screen, so the
/// factor behaviour is identical to cold-boot unlock.
Future<bool> showConfirmIdentitySheet(
  BuildContext context, {
  String title = "Confirm it's you",
  String subtitle = 'A quick identity check keeps this account safe.',
}) async {
  // Drag handle only makes sense in the bottom-sheet (phone) presentation;
  // the dialog (tablet/desktop) has its own framing.
  final showHandle = !isWideViewport(context);
  final result = await showAdaptiveModal<bool>(
    context,
    child: ConfirmIdentitySheet(
      title: title,
      subtitle: subtitle,
      showHandle: showHandle,
    ),
  );
  return result ?? false;
}

class ConfirmIdentitySheet extends ConsumerStatefulWidget {
  const ConfirmIdentitySheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.showHandle = true,
  });

  final String title;
  final String subtitle;

  /// Draws the bottom-sheet drag handle. False in dialog (wide) mode.
  final bool showHandle;

  @override
  ConsumerState<ConfirmIdentitySheet> createState() =>
      _ConfirmIdentitySheetState();
}

class _ConfirmIdentitySheetState extends ConsumerState<ConfirmIdentitySheet> {
  bool _busy = false;
  String? _errorText;
  bool _passwordMode = false;

  final PinKeypadController _pinController = PinKeypadController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _succeed() {
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _onPin(String digits) async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      setState(() => _errorText = 'Please sign in again.');
      _pinController.clear();
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
      ok: (_) => _succeed(),
      err: (failure) {
        setState(() {
          _busy = false;
          _errorText = failure.message;
        });
        _pinController.clear();
      },
    );
  }

  Future<void> _onBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await ref.read(authenticateWithBiometricUseCaseProvider)(
      reason: 'Confirm your identity',
    );
    if (!mounted) return;
    // Biometric failure / cancel falls through silently to the PIN keypad,
    // mirroring the Privacy Lock screen's behaviour.
    result.fold(
      ok: (_) => _succeed(),
      err: (_) => setState(() => _busy = false),
    );
  }

  Future<void> _onSecurityKey() async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await ref.read(verifyWebauthnUseCaseProvider)(
      userId: user.uid,
    );
    if (!mounted) return;
    result.fold(
      ok: (_) => _succeed(),
      err: (failure) => setState(() {
        _busy = false;
        _errorText = failure.isUserCanceled ? null : failure.message;
      }),
    );
  }

  Future<void> _onPassword() async {
    if (_busy) return;
    final user = ref.read(currentUserStreamProvider).value;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      setState(() => _errorText = 'This account has no password sign-in.');
      return;
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .reauthenticate(
          AuthCredentials.password(email: email, password: password),
        );
    if (!mounted) return;
    result.fold(
      ok: (_) => _succeed(),
      err: (failure) => setState(() {
        _busy = false;
        _errorText = failure.message;
      }),
    );
  }

  bool _hasBiometric(BiometricCapability? cap) =>
      cap != null &&
      cap.isAvailable &&
      cap.hasEnrolledBiometrics &&
      cap.userOptedIn;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final cap = ref.watch(biometricCapabilityProvider).value;
    final canBiometric = _hasBiometric(cap);
    final webauthnAvailable = ref.watch(webauthnAvailableProvider);
    final hasCredential = ref.watch(webauthnCredentialProvider).value != null;
    final canSecurityKey = webauthnAvailable && hasCredential;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHandle) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mb.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: MbFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: mb.textDim,
                  tooltip: 'Cancel',
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: MbFonts.nunito(
                fontSize: 13,
                height: 1.4,
                color: mb.textDim,
              ),
            ),
            const SizedBox(height: 16),
            if (_passwordMode)
              _PasswordPanel(
                mb: mb,
                controller: _passwordController,
                busy: _busy,
                errorText: _errorText,
                onConfirm: _onPassword,
                onBack: _busy
                    ? null
                    : () => setState(() {
                        _passwordMode = false;
                        _errorText = null;
                      }),
              )
            else ...[
              // Alternative factors first - compact and always visible, so
              // they're never buried below the (tall) keypad in the scroll
              // view.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (canBiometric)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _onBiometric,
                      icon: const Icon(Icons.fingerprint, size: 18),
                      label: const Text('Biometric'),
                    ),
                  if (canSecurityKey)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _onSecurityKey,
                      icon: const Icon(Icons.key, size: 18),
                      label: const Text('Security key'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _passwordMode = true;
                            _errorText = null;
                          }),
                    icon: const Icon(Icons.password, size: 18),
                    label: const Text('Password'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Or enter your PIN',
                textAlign: TextAlign.center,
                style: MbFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mb.textDim,
                ),
              ),
              const SizedBox(height: 8),
              PinKeypad(
                controller: _pinController,
                enabled: !_busy,
                onComplete: _onPin,
                errorText: _errorText,
                // Autofocus so a physical keyboard can type the PIN, same as
                // the Privacy Lock screen. The factor options above stay put
                // (a plain Focus doesn't scroll its scrollable - only text
                // fields do).
                autofocusKeyboard: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordPanel extends StatelessWidget {
  const _PasswordPanel({
    required this.mb,
    required this.controller,
    required this.busy,
    required this.errorText,
    required this.onConfirm,
    required this.onBack,
  });

  final MbColors mb;
  final TextEditingController controller;
  final bool busy;
  final String? errorText;
  final VoidCallback onConfirm;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MbInputField(
          label: 'Password',
          controller: controller,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onConfirm(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: MbFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).extension<MbColors>()?.destructiveText ??
                  Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        MbPrimaryButton(
          label: 'Confirm',
          loading: busy,
          onPressed: busy ? null : onConfirm,
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: onBack, child: const Text('Use PIN instead')),
      ],
    );
  }
}

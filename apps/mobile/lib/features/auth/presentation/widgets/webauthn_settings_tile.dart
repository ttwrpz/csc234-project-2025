import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart'
    show
        currentUserStreamProvider,
        registerWebauthnUseCaseProvider,
        webauthnAvailableProvider,
        webauthnCredentialProvider;
import '../../domain/entities/webauthn_credential.dart';
import '../../domain/entities/webauthn_register_failure.dart';

/// Settings → Privacy tile for WebAuthn / security keys (ADR-0014).
///
/// State matrix:
/// * **Build-time flag off (`kEnableWebauthn == false`)** → renders the
///   tile in a disabled "preview" state with copy explaining the
///   feature is staged for a future release once a production origin
///   is provisioned. The tap is a no-op + snackbar.
/// * **Flag on, not web** → renders disabled with "Web only — open
///   MoodBloom in Chrome / Edge / Safari to register a security key."
/// * **Flag on, web, no credential** → "Set up a security key" — tap
///   invokes [RegisterWebauthnUseCase], handling each failure mode
///   distinctly (notProvisioned snackbar, pinRequired routes to
///   `/privacy/setup`, userCanceled is silent, anything else surfaces a
///   compact error snackbar).
/// * **Flag on, web, credential registered** → shows the credential's
///   creation date; "Remove security key" affordance is deferred to
///   v1.5.1.
class WebauthnSettingsTile extends ConsumerStatefulWidget {
  const WebauthnSettingsTile({super.key});

  @override
  ConsumerState<WebauthnSettingsTile> createState() =>
      _WebauthnSettingsTileState();
}

class _WebauthnSettingsTileState extends ConsumerState<WebauthnSettingsTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final available = ref.watch(webauthnAvailableProvider);

    // `webauthnAvailableProvider` short-circuits to `false` when either
    // `kEnableWebauthn` is `false` OR `kIsWeb` is `false`. The two
    // disabled-state branches below pick a friendly subtitle so the user
    // understands why the tile is greyed out rather than just seeing a
    // disabled affordance with no explanation.
    if (!available) {
      return _DisabledTile(
        mb: mb,
        title: 'Security key (WebAuthn)',
        subtitle: kIsWeb
            // On web with the build flag off → preview-only copy.
            ? 'Coming in a future release - a hardware security key or '
                  'platform authenticator (Touch ID, Windows Hello) as a '
                  'stronger PIN fallback. Waiting on a production origin '
                  'per ADR-0014.'
            // Off-web → web-only copy directing the user to a browser.
            : 'Web only. Open MoodBloom in Chrome, Edge, or Safari to '
                  'register a security key. On Android, biometric unlock '
                  'is already available above.',
      );
    }

    // Flag on AND web (or test-override true). Read the credential
    // stream and render the appropriate state.
    final credentialAsync = ref.watch(webauthnCredentialProvider);
    return credentialAsync.when(
      data: (credential) => credential == null
          ? _NoCredentialTile(
              mb: mb,
              available: available,
              busy: _busy,
              onRegister: _onRegister,
            )
          : _RegisteredTile(
              mb: mb,
              credential: credential,
              onRemove: _onRemovePlaceholder,
            ),
      loading: () => _LoadingTile(mb: mb),
      error: (_, _) => _ErrorTile(mb: mb),
    );
  }

  // ────────────────────────────────────────────────────────────────────

  Future<void> _onRegister() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in before registering a key.')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(registerWebauthnUseCaseProvider)(
      userId: user.uid,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      ok: (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Security key registered.')),
        );
      },
      err: (failure) => _handleRegisterFailure(failure, messenger),
    );
  }

  void _handleRegisterFailure(
    WebauthnRegisterFailure failure,
    ScaffoldMessengerState messenger,
  ) {
    if (failure.isUserCanceled) {
      // User dismissed the browser prompt — silent.
      return;
    }
    if (failure.isPinRequired) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      // The settings card lives inside a GoRouter shell, so a `go`
      // is fine; the user lands on the privacy setup flow and
      // returns to /settings after completing it.
      context.go('/privacy/setup');
      return;
    }
    if (failure.isNotProvisioned) {
      // Deploy-guard snackbar — server-side fence per ADR-0014 §F.
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // network / verificationFailed / unknown — generic compact error.
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }

  void _onRemovePlaceholder() {
    // Remove is deferred to v1.5.1 — the assertion ceremony is required
    // before we can safely retire a credential (we have to confirm the
    // user owns the key they're trying to remove, and the CF surface
    // for that lands with the assertion path). For v1.5 the user can
    // remove via account deletion (the wipeUserData cascade drains the
    // `webauthn/` subcollection).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Remove-credential lands in v1.5.1. For now, '
          'account deletion drops the registered key.',
        ),
      ),
    );
  }
}

class _DisabledTile extends StatelessWidget {
  const _DisabledTile({
    required this.mb,
    required this.title,
    required this.subtitle,
  });

  final MbColors mb;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.key_outlined, color: mb.textDim),
      title: Text(
        title,
        style: MbFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim, height: 1.35),
      ),
      enabled: false,
    );
  }
}

class _NoCredentialTile extends StatelessWidget {
  const _NoCredentialTile({
    required this.mb,
    required this.available,
    required this.busy,
    required this.onRegister,
  });

  final MbColors mb;
  final bool available;
  final bool busy;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.key_outlined, color: theme.colorScheme.primary),
      title: Text(
        'Set up a security key',
        style: MbFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
      ),
      subtitle: Text(
        'Register a hardware key or this device as a stronger fallback '
        'to your PIN. Optional - biometric and PIN already protect your '
        'journal.',
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim, height: 1.35),
      ),
      trailing: const Icon(Icons.chevron_right),
      enabled: available && !busy,
      onTap: available && !busy ? onRegister : null,
    );
  }
}

class _RegisteredTile extends StatelessWidget {
  const _RegisteredTile({
    required this.mb,
    required this.credential,
    required this.onRemove,
  });

  final MbColors mb;
  final WebauthnCredential credential;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = credential.createdAt;
    final monthShort = _monthShort(createdAt.month);
    final subtitle = credential.lastUsedAt != null
        ? 'Registered $monthShort ${createdAt.day}. '
              'Last used ${_monthShort(credential.lastUsedAt!.month)} '
              '${credential.lastUsedAt!.day}.'
        : 'Registered $monthShort ${createdAt.day}.';
    return ListTile(
      leading: Icon(Icons.key, color: theme.colorScheme.primary),
      title: Text(
        'Security key registered',
        style: MbFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
      ),
      trailing: Icon(Icons.chevron_right, color: mb.textDim),
      onTap: onRemove,
    );
  }

  static String _monthShort(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({required this.mb});
  final MbColors mb;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text(
        'Checking security key...',
        style: MbFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.mb});
  final MbColors mb;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.key_off_outlined, color: mb.textDim),
      title: Text(
        'Security key unavailable',
        style: MbFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mb.text,
        ),
      ),
      subtitle: Text(
        'Could not reach the security-key service. Retry from Settings.',
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
      ),
      enabled: false,
    );
  }
}

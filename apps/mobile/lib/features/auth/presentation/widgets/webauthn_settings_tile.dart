import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/feature_flags.dart' show kEnableWebauthn;
import '../../data/providers.dart'
    show webauthnAvailableProvider, webauthnCredentialProvider;

/// Settings → Privacy tile for WebAuthn / security keys (ADR-0014).
///
/// State matrix:
/// * **Build-time flag off (`kEnableWebauthn == false`)** → renders the
///   tile in a disabled "preview" state with copy explaining the
///   feature is staged for v1.5.1 once a production origin is
///   provisioned. The tap is a no-op + snackbar.
/// * **Flag on, not web** → renders disabled with "Web only — open
///   MoodBloom in Chrome / Edge / Safari to register a security key."
/// * **Flag on, web, no credential** → "Set up a security key" — tap
///   opens the registration ceremony.
/// * **Flag on, web, credential registered** → shows the credential's
///   creation date + a "Remove security key" affordance.
///
/// The tile is always visible so users can see the feature exists and
/// understand its state. The ADR-0014 deferral footer (origin pending)
/// is surfaced as the subtitle in the disabled state — the user is
/// told why it's not active, not just that it isn't.
class WebauthnSettingsTile extends ConsumerWidget {
  const WebauthnSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final available = ref.watch(webauthnAvailableProvider);

    // Disabled preview when the build-time flag is off.
    if (!kEnableWebauthn) {
      return _DisabledTile(
        mb: mb,
        title: 'Security key (WebAuthn)',
        subtitle:
            'Coming in v1.5.1 — a hardware security key or platform '
            'authenticator (Touch ID, Windows Hello) as a stronger PIN '
            'fallback. Waiting on a production origin per ADR-0014.',
      );
    }

    // Flag on but not on web — local_auth covers Android/iOS, so the
    // WebAuthn path is web-specific by design.
    if (!kIsWeb) {
      return _DisabledTile(
        mb: mb,
        title: 'Security key (WebAuthn)',
        subtitle:
            'Web only. Open MoodBloom in Chrome, Edge, or Safari to '
            'register a security key. On Android, biometric unlock is '
            'already available above.',
      );
    }

    // Flag on AND web. Read the credential stream and render the
    // appropriate state.
    final credentialAsync = ref.watch(webauthnCredentialProvider);
    return credentialAsync.when(
      data: (credential) => credential == null
          ? _NoCredentialTile(mb: mb, available: available)
          : _RegisteredTile(mb: mb, credential: credential),
      loading: () => _LoadingTile(mb: mb),
      error: (_, _) => _ErrorTile(mb: mb),
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
  const _NoCredentialTile({required this.mb, required this.available});

  final MbColors mb;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.key_outlined, color: theme.colorScheme.primary),
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
        'to your PIN. Optional — biometric and PIN already protect your '
        'journal.',
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim, height: 1.35),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // v1.5.1: invoke RegisterWebauthnUseCase here. For now (flag is
        // on but the production origin may still be empty) surface a
        // friendly message instead of triggering the JS-interop call.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Security-key registration lands in v1.5.1 once the '
              'production origin is provisioned.',
            ),
          ),
        );
      },
    );
  }
}

class _RegisteredTile extends StatelessWidget {
  const _RegisteredTile({required this.mb, required this.credential});

  final MbColors mb;
  // ignore: avoid_dynamic, prefer_typing_uninitialized_variables
  final dynamic credential;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = credential.createdAt as DateTime;
    final monthShort = _monthShort(createdAt.month);
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
        'Registered $monthShort ${createdAt.day}. Tap to remove.',
        style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
      ),
      trailing: Icon(Icons.chevron_right, color: mb.textDim),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Remove-credential lands in v1.5.1 with the assertion '
              'ceremony.',
            ),
          ),
        );
      },
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
        'Checking security key…',
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

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_flags.dart' show kEnableWebauthn;
import '../data/providers.dart' show signInWithWebauthnUseCaseProvider;
import 'controllers/sign_in_controller.dart';
import 'controllers/sign_in_state.dart' show SignInSubmitMethod;
import 'widgets/google_sign_in_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// True while the cold-boot security-key ceremony is in flight. Local
  /// to the screen (not the sign-in controller) because the WebAuthn flow
  /// doesn't go through the email/Google submit path.
  bool _webauthnBusy = false;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(signInControllerProvider.notifier);
    _emailController.addListener(
      () => controller.setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => controller.setPassword(_passwordController.text),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Cold-boot security-key sign-in (web only, behind `kEnableWebauthn`).
  /// Runs the usernameless WebAuthn ceremony and exchanges the resulting
  /// custom token for a Firebase session; on success the auth-state stream
  /// emits and the router redirect lands the user on `/home`. The browser
  /// prompt is the user's visual feedback, so a cancel is silent; other
  /// failures surface the compassionate failure message. When the server
  /// origin isn't provisioned yet the CF returns `webauthn_not_provisioned`
  /// → mapped to a network failure, so the user simply falls back to PIN /
  /// email without a dead-end.
  Future<void> _onWebauthn() async {
    if (_webauthnBusy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _webauthnBusy = true);
    final result = await ref.read(signInWithWebauthnUseCaseProvider)();
    if (!mounted) return;
    setState(() => _webauthnBusy = false);
    switch (result) {
      case Ok():
        // Auth-state stream emits; the router redirect navigates to /home.
        break;
      case Err(:final failure):
        if (failure.isUserCanceled) return; // dismissed prompt — silent.
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: mb.bg,
      // Centred form column. Sign-in needs neither full screen width nor a
      // ListView's vertical bias on desktop — capping at 420 dp and
      // centring vertically keeps the form compact and keeps the brand
      // mark in the visual sweet spot regardless of viewport size.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const MbBrandSvg(
                            size: 48,
                            color: MoodBloomColors.seed,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'MoodBloom',
                            style: MbFonts.fraunces(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: mb.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to tend your garden',
                            style: MbFonts.nunito(
                              fontSize: 14,
                              color: mb.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    MbInputField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    MbInputField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: MbFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mb.textDim,
                          ),
                        ),
                      ),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        style: MbFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    MbPrimaryButton(
                      label: 'Sign in',
                      onPressed: state.isSubmitting ? null : controller.submit,
                      // Only spin when the password flow is the one
                      // actively in flight — the Google flow disables
                      // this button but no longer triggers its spinner.
                      loading:
                          state.submittingWith == SignInSubmitMethod.password,
                    ),
                    const SizedBox(height: 16),
                    _OrDivider(mb: mb),
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      // Disabled while ANY flow is submitting, but the
                      // spinner only lights up for the Google flow.
                      onPressed: state.isSubmitting
                          ? null
                          : controller.submitGoogle,
                      isLoading:
                          state.submittingWith == SignInSubmitMethod.google,
                    ),
                    // Web-only WebAuthn entry point, behind the
                    // `kEnableWebauthn` build flag. No native "Use
                    // biometric" affordance here — biometric at the
                    // cold-boot sign-in stage is a no-op:
                    // `LocalAuthentication.authenticate()` returns
                    // success but produces no credentials, and the
                    // router redirect bounces the user back to
                    // /sign-in because Firebase has no cached session.
                    // The genuine biometric re-auth flow lives at the
                    // `/biometric-gate` route, which the router enters
                    // automatically when an already-signed-in user
                    // re-opens the app with biometric opt-in on.
                    if (kIsWeb && kEnableWebauthn) ...[
                      const SizedBox(height: 10),
                      MbGhostButton(
                        label: 'Use security key',
                        leading: const Icon(Icons.key, size: 18),
                        onPressed: (state.isSubmitting || _webauthnBusy)
                            ? null
                            : _onWebauthn,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Two-colour footer link: the prompt noun reads in the
                    // dim text colour, the call-to-action verb in seed
                    // green w700 — same pattern as the prototype's
                    // `SignInScreen` "New here? Create an account".
                    Center(
                      child: _AuthFooterLink(
                        prompt: "Don't have an account? ",
                        action: 'Create one',
                        onTap: () => context.push('/sign-up'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'By continuing you agree to our gentle terms',
                        style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
                      ),
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

/// Thin "—— or ——" separator. Matches the prototype's auth divider.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.mb});
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: mb.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or',
            style: MbFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mb.textDim,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: mb.line)),
      ],
    );
  }
}

/// Two-tone footer link used at the bottom of Sign In / Sign Up. The
/// [prompt] reads in the dim text colour; [action] is the tappable
/// affordance, painted in the brand seed colour with w700 weight.
/// Tapping anywhere on the row fires [onTap] — Semantics is wired up
/// so screen readers announce "Create one, button" rather than
/// reading the prompt as the activation phrase.
class _AuthFooterLink extends StatelessWidget {
  const _AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      button: true,
      label: action,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: prompt,
                  style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
                ),
                TextSpan(
                  text: action,
                  style: MbFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MoodBloomColors.seed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

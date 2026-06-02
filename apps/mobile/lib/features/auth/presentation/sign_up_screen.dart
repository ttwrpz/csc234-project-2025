import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../legal/presentation/legal_document_screen.dart'
    show showLegalDocument;
import '../../legal/presentation/privacy_policy_screen.dart';
import '../../legal/presentation/terms_of_service_screen.dart';
import 'controllers/sign_up_controller.dart';
import 'widgets/google_sign_in_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Owned by the State and disposed below; creating them inline in build()
  // leaked a recognizer on every keystroke rebuild and left the taps flaky.
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(signUpControllerProvider.notifier);
    _nameController.addListener(
      () => controller.setDisplayName(_nameController.text),
    );
    _emailController.addListener(
      () => controller.setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => controller.setPassword(_passwordController.text),
    );
    _confirmController.addListener(
      () => controller.setConfirmPassword(_confirmController.text),
    );
    // Overlay, not a route push - see sign_in_screen.dart for why
    // (router redirect can swallow `/legal/*` on the unauthed screen).
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => showLegalDocument(context, TermsOfServiceScreen.document);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => showLegalDocument(context, PrivacyPolicyScreen.document);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final controller = ref.read(signUpControllerProvider.notifier);
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: mb.bg,
      // Centred form column. See sign_in_screen.dart for the rationale -
      // capping at 420 dp keeps the form compact on desktop and stops a
      // ListView from spreading the brand mark across half the screen.
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
                            'A quiet space to notice how you feel',
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
                      label: 'Your name',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
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
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    MbInputField(
                      label: 'Confirm password',
                      controller: _confirmController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.submit(),
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
                      label: 'Create account',
                      onPressed: state.isSubmitting ? null : controller.submit,
                      loading: state.isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    _OrDivider(mb: mb),
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      onPressed: controller.submitGoogle,
                      isLoading: state.isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _AuthFooterLink(
                        prompt: 'Already have an account? ',
                        action: 'Sign in',
                        onTap: () => context.go('/sign-in'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing you agree to our ',
                          style: MbFonts.nunito(
                            fontSize: 11,
                            color: mb.textDim,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: MbFonts.nunito(
                                fontSize: 11,
                                color: mb.text,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsRecognizer,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: MbFonts.nunito(
                                fontSize: 11,
                                color: mb.text,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyRecognizer,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
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

/// Two-tone footer link - see `sign_in_screen.dart` for the rationale.
/// Duplicated here intentionally so each screen file stays
/// self-contained; the visual treatment is small enough that lifting
/// it to a shared widget would obscure more than it would share.
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

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/forgot_password_controller.dart';

/// Single-purpose screen that takes an email address and asks Firebase
/// to send a password-reset link. On success the form swaps for a
/// confirmation panel so the user is never left wondering whether the
/// request went through. Errors render inline beside the form.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    _emailController.addListener(
      () => controller.setEmail(_emailController.text),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: state.isSent
                  ? _sentPanel(context, mb)
                  : AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              MbIconButton(
                                icon: const Icon(Icons.arrow_back),
                                semanticLabel: 'Back to sign in',
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    // ignore: discarded_futures
                                    GoRouter.of(context).go('/sign-in');
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Reset password',
                                style: MbFonts.fraunces(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: mb.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Forgot your password?',
                            style: MbFonts.fraunces(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: mb.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter the email you signed up with. We'll "
                            'send a link to set a new password.',
                            style: MbFonts.nunito(
                              fontSize: 14,
                              height: 1.5,
                              color: mb.textDim,
                            ),
                          ),
                          const SizedBox(height: 20),
                          MbInputField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
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
                            label: 'Send reset link',
                            onPressed: state.isSubmitting
                                ? null
                                : controller.submit,
                            loading: state.isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => _backToSignIn(context),
                              child: const Text('Back to sign in'),
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

  Widget _sentPanel(BuildContext context, MbColors mb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Icon(Icons.mark_email_read_outlined, size: 56, color: mb.text),
        ),
        const SizedBox(height: 16),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: MbFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "If an account exists for the email you entered, we've sent a "
          'link to reset your password. The link may take a minute to '
          "arrive - be sure to check your spam folder if you don't see it.",
          textAlign: TextAlign.center,
          style: MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.textDim),
        ),
        const SizedBox(height: 24),
        MbGhostButton(
          label: 'Back to sign in',
          onPressed: () => _backToSignIn(context),
        ),
      ],
    );
  }

  /// Pops back to the sign-in screen. When the screen was reached via
  /// deep-link with no parent route to pop into, fall back to a
  /// `go('/sign-in')` so the user always lands somewhere sensible.
  void _backToSignIn(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sign-in');
    }
  }
}

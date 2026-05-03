import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'controllers/sign_up_controller.dart';
import 'widgets/brand_mark.dart';
import 'widgets/google_sign_in_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = ref.read(signUpControllerProvider.notifier);
    _emailController.addListener(
      () => controller.setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => controller.setPassword(_passwordController.text),
    );
    _confirmController.addListener(
      () => controller.setConfirmPassword(_confirmController.text),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AutofillGroup(
            child: ListView(
              children: [
                const SizedBox(height: 36),
                Center(
                  child: Column(
                    children: [
                      const BrandMark(),
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
                        style: MbFonts.nunito(fontSize: 14, color: mb.textDim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
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
                const SizedBox(height: 14),
                _OrDivider(mb: mb),
                const SizedBox(height: 14),
                GoogleSignInButton(
                  onPressed: controller.submitGoogle,
                  isLoading: state.isSubmitting,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'By continuing you agree to our gentle terms.',
                    style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
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
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
        ),
        Expanded(child: Container(height: 1, color: mb.line)),
      ],
    );
  }
}

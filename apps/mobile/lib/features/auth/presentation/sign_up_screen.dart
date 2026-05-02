import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'controllers/sign_up_controller.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpControllerProvider);
    final controller = ref.read(signUpControllerProvider.notifier);
    final showGoogle =
        !kIsWeb; // Web Google sign-in goes through Firebase popup;
    // we hide the dedicated button to keep the sign-up surface single-path on web.

    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl),
          child: AutofillGroup(
            child: ListView(
              children: [
                const SizedBox(height: MoodBloomSpacing.xxl),
                Text(
                  'A quiet space to notice how you feel.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: MoodBloomSpacing.xl),
                AuthTextField(
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setEmail,
                ),
                AuthTextField(
                  label: 'Password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: controller.setPassword,
                ),
                AuthTextField(
                  label: 'Confirm password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onChanged: controller.setConfirmPassword,
                  onSubmitted: (_) => controller.submit(),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: MoodBloomSpacing.sm),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: MoodBloomSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: MoodBloomSpacing.tapTargetMin,
                  child: FilledButton(
                    onPressed: state.isSubmitting ? null : controller.submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                ),
                if (showGoogle) ...[
                  const SizedBox(height: MoodBloomSpacing.lg),
                  GoogleSignInButton(
                    onPressed: controller.submitGoogle,
                    isLoading: state.isSubmitting,
                  ),
                ],
                const SizedBox(height: MoodBloomSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Already have an account? Sign in'),
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

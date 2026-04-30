import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'controllers/sign_in_controller.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final showGoogle = !kIsWeb; // Web Google sign-in is gated on OAuth setup.

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome back')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoodBloomSpacing.xl),
          child: AutofillGroup(
            child: ListView(
              children: [
                const SizedBox(height: MoodBloomSpacing.xxl),
                Text(
                  'Sign in to keep tracking your moods.',
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
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onChanged: controller.setPassword,
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
                        : const Text('Sign in'),
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
                    onPressed: () => context.push('/sign-up'),
                    child: const Text('Create an account'),
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

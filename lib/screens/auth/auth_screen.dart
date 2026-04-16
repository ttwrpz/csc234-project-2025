import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await auth.registerWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Enter your email address first.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(email);
    if (mounted) {
      if (success) {
        ErrorHandler.showSuccessSnackBar(
          context, 'Password reset email sent! Check your inbox.');
      } else {
        ErrorHandler.showErrorSnackBar(
          context, auth.error ?? 'Failed to send reset email.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Text(
                      '\u{1F33B}',
                      style: const TextStyle(fontSize: 64),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MoodBloom',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Welcome back!' : 'Create your account',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.error == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Display name (Register only)
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: Validators.displayName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      textInputAction:
                          _isLogin ? TextInputAction.done : TextInputAction.next,
                      onFieldSubmitted: _isLogin ? (_) => _submit() : null,
                    ),

                    // Password strength indicator (Register only)
                    if (!_isLogin) ...[
                      const SizedBox(height: 8),
                      ValueListenableBuilder(
                        valueListenable: _passwordController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final strength =
                              Validators.getPasswordStrength(value.text);
                          final theme = Theme.of(context);
                          Color color;
                          switch (strength) {
                            case PasswordStrength.weak:
                              color = theme.colorScheme.error;
                            case PasswordStrength.medium:
                              color = theme.colorScheme.tertiary;
                            case PasswordStrength.strong:
                              color = theme.colorScheme.primary;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: strength.value,
                                backgroundColor: theme.dividerColor,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Password strength: ${strength.label}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: color),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Confirm password
                      TextFormField(
                        controller: _confirmController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        obscureText: _obscureConfirm,
                        validator: (value) => Validators.confirmPassword(
                            value, _passwordController.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],

                    // Forgot password (Login only)
                    if (_isLogin) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isLogin ? 'Login' : 'Register'),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Divider with OR
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign-In
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return OutlinedButton.icon(
                          onPressed:
                              auth.isLoading ? null : _signInWithGoogle,
                          icon: const Text('G',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          label: const Text('Continue with Google'),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Toggle login/register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(_isLogin ? 'Register' : 'Login'),
                        ),
                      ],
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

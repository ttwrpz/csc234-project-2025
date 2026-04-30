import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Branded "Continue with Google" button. Hidden by callers when Google
/// sign-in is unavailable on the current platform (e.g. Web without an
/// OAuth client ID configured).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MoodBloomSpacing.tapTargetMin,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

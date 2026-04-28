import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Themed text field used by sign-in and sign-up forms. Wraps Material's
/// `TextField` with design-system spacing and a 48dp minimum tap height.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoodBloomSpacing.sm),
      child: TextField(
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: MoodBloomSpacing.lg,
            vertical: MoodBloomSpacing.md,
          ),
        ),
      ),
    );
  }
}

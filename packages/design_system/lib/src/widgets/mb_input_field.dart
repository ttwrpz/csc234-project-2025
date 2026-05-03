import 'mb_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';

/// Tiny uppercase label inside a soft container with a borderless TextField.
/// Replaces the per-feature `AuthTextField` so the auth screens, settings
/// edit forms, etc. all share one shape.
class MbInputField extends StatelessWidget {
  const MbInputField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.autofillHints,
    this.errorText,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mb.card,
            border: Border.all(
              color: hasError ? theme.colorScheme.error : mb.line,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: MbFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: mb.textDim,
                ),
              ),
              const SizedBox(height: 2),
              TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onSubmitted: onSubmitted,
                autofillHints: autofillHints,
                textInputAction: textInputAction,
                inputFormatters: inputFormatters,
                enabled: enabled,
                style: MbFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: mb.text,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              errorText!,
              style: MbFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

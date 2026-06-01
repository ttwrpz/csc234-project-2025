import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Optional context note for a mood entry. Visually a 4-row borderless
/// `TextField` inside an [MbCard] (the parent screen wraps in the card and
/// places the attach buttons + counter below the field).
///
/// Hard-capped at 500 characters - the parent renders the "n/500" counter so
/// we keep the field's chrome minimal.
///
/// Stateful so we keep a single [TextEditingController] across rebuilds and
/// can clear the field when the parent resets the draft to empty after a
/// successful save.
class MoodTextField extends StatefulWidget {
  const MoodTextField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const int maxChars = 500;

  @override
  State<MoodTextField> createState() => _MoodTextFieldState();
}

class _MoodTextFieldState extends State<MoodTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant MoodTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync only when the upstream value diverges (e.g. draft reset on save).
    // Avoid clobbering during typing - we are the source of those changes.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return TextField(
      controller: _controller,
      onChanged: (text) {
        // Hard-clamp here as well as in the field's `maxLength` so paste
        // operations can't sneak past the cap.
        if (text.length > MoodTextField.maxChars) {
          final clamped = text.substring(0, MoodTextField.maxChars);
          _controller.value = TextEditingValue(
            text: clamped,
            selection: TextSelection.collapsed(offset: clamped.length),
          );
          widget.onChanged(clamped);
          return;
        }
        widget.onChanged(text);
      },
      maxLength: MoodTextField.maxChars,
      maxLines: 4,
      minLines: 4,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: MbFonts.nunito(fontSize: 14, height: 1.5, color: mb.text),
      decoration: InputDecoration(
        hintText: 'Optional - whatever feels true right now.',
        hintStyle: MbFonts.nunito(fontSize: 14, color: mb.textDim),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
    );
  }
}

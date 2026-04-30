import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Optional context note for a mood entry. Hard-capped at 500 characters by
/// `TextField.maxLength`, which also surfaces the default `{n}/500` counter.
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

  static const int _maxChars = 500;

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
    // Avoid clobbering during typing — we are the source of those changes.
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
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLength: MoodTextField._maxChars,
      maxLines: null,
      minLines: 3,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'A line about your day, if you like.',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusMd),
        ),
      ),
    );
  }
}

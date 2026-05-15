import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/pin.dart';

/// 6-digit numeric keypad. Shared between PIN setup (two-pass entry)
/// and PIN verify (the History unlock flow).
///
/// State is held internally — the parent receives only the completed
/// PIN via [onComplete] once 6 digits are typed. Intermediate progress
/// is rendered as filled / unfilled dots so the user never sees their
/// digits echoed (the screen has no `Text` rendering of the secret).
///
/// Use [reset] (via [PinKeypadController]) to clear the entry after a
/// mismatch or wrong-PIN error.
class PinKeypad extends StatefulWidget {
  const PinKeypad({
    super.key,
    required this.onComplete,
    this.enabled = true,
    this.controller,
    this.errorText,
  });

  /// Fired once the user has typed [Pin.length] digits. The string is
  /// guaranteed to be exactly 6 numeric characters by the keypad
  /// (no `Pin.tryFrom` shape check needed at the call site, though
  /// callers still go through their use case for setup/verify).
  final void Function(String pinDigits) onComplete;

  /// When false, all key taps are ignored. The dots stay visible but
  /// muted, and the keypad looks disabled. Used during the locked
  /// state (PinVerifyFailure.locked) and while awaiting network IO.
  final bool enabled;

  /// Optional controller exposing `clear()` so the parent can reset
  /// the keypad after a wrong-PIN / mismatch event.
  final PinKeypadController? controller;

  /// Inline message shown above the keypad — used for mismatch /
  /// "wrong PIN" / "too many tries" copy. Pass null when there is no
  /// error to render.
  final String? errorText;

  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

/// External handle for the parent to clear the keypad. Required because
/// the keypad owns its own buffer (we don't surface the in-progress
/// secret to the parent).
class PinKeypadController {
  void Function()? _onClear;

  void clear() => _onClear?.call();

  void _attach(void Function() onClear) => _onClear = onClear;

  void _detach() => _onClear = null;
}

class _PinKeypadState extends State<PinKeypad> {
  final StringBuffer _buffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_clear);
  }

  @override
  void didUpdateWidget(covariant PinKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_clear);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void _clear() {
    if (!mounted) return;
    setState(_buffer.clear);
  }

  void _onDigit(int digit) {
    if (!widget.enabled) return;
    if (_buffer.length >= Pin.length) return;
    setState(() => _buffer.write(digit));
    if (_buffer.length == Pin.length) {
      widget.onComplete(_buffer.toString());
    }
  }

  void _onBackspace() {
    if (!widget.enabled) return;
    if (_buffer.isEmpty) return;
    final current = _buffer.toString();
    setState(() {
      _buffer
        ..clear()
        ..write(current.substring(0, current.length - 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dots(length: Pin.length, filled: _buffer.length, mb: mb),
        const SizedBox(height: 12),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.errorText!,
              style: MbFonts.nunito(
                fontSize: 13,
                color: MoodBloomColors.coralText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 8),
        _Keys(
          enabled: widget.enabled,
          onDigit: _onDigit,
          onBackspace: _onBackspace,
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.filled, required this.mb});
  final int length;
  final int filled;
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? mb.text : Colors.transparent,
                border: Border.all(color: mb.textDim.withValues(alpha: 0.5)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });
  final bool enabled;
  final void Function(int digit) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    // Standard phone keypad layout: 1-2-3 / 4-5-6 / 7-8-9 / blank-0-backspace.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([1, 2, 3]),
        _row([4, 5, 6]),
        _row([7, 8, 9]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Spacer(),
            _digitKey(0),
            _backspaceKey(),
          ],
        ),
      ],
    );
  }

  Widget _row(List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [for (final d in digits) _digitKey(d)],
    );
  }

  Widget _digitKey(int digit) {
    return _KeypadButton(
      label: '$digit',
      enabled: enabled,
      onPressed: () => onDigit(digit),
    );
  }

  Widget _backspaceKey() {
    return _KeypadButton(
      icon: Icons.backspace_outlined,
      semanticsLabel: 'Backspace',
      enabled: enabled,
      onPressed: onBackspace,
    );
  }
}

class _Spacer extends StatelessWidget {
  const _Spacer();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 72, height: 72);
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    this.semanticsLabel,
    required this.enabled,
    required this.onPressed,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final String? semanticsLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final foreground = enabled ? mb.text : mb.textDim;
    final child = icon != null
        ? Icon(icon, color: foreground, size: 24)
        : Text(
            label!,
            style: MbFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          );
    return Semantics(
      label: semanticsLabel ?? label,
      button: true,
      enabled: enabled,
      child: SizedBox(
        width: 72,
        height: 72,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: child,
        ),
      ),
    );
  }
}

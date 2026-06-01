import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/pin.dart';

/// 6-digit numeric keypad. Shared between PIN setup (two-pass entry)
/// and PIN verify (the History unlock flow).
///
/// State is held internally - the parent receives only the completed
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

  /// Inline message shown above the keypad - used for mismatch /
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

class _PinKeypadState extends State<PinKeypad>
    with SingleTickerProviderStateMixin {
  final StringBuffer _buffer = StringBuffer();
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_clear);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
  }

  @override
  void didUpdateWidget(covariant PinKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_clear);
    }
    // A freshly-surfaced error (wrong PIN / mismatch) shakes the dots row
    // for a quick, calm "that didn't match" cue without a jarring colour
    // flash.
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _shakeController.dispose();
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
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final t = _shakeController.value;
            // Damped horizontal oscillation: a few quick swings that decay
            // to rest. Zero offset when idle so layout is untouched.
            final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 4) * 9 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: _Dots(length: Pin.length, filled: _buffer.length, mb: mb),
        ),
        const SizedBox(height: 12),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.errorText!,
              style: MbFonts.nunito(
                fontSize: 13,
                // Theme-aware destructive-text token - `coralText` is
                // the design-system "destructive text on cream" token
                // and is not dark-safe, so prefer the MbColors
                // extension when present.
                color:
                    theme.extension<MbColors>()?.destructiveText ??
                    theme.colorScheme.error,
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
          // Fixed-size outer box keeps the row geometry stable while the
          // inner dot animates its fill / size on each keypress.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: i < filled ? 17 : 13,
                  height: i < filled ? 17 : 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled
                        ? MoodBloomColors.seed
                        : Colors.transparent,
                    border: Border.all(
                      color: i < filled
                          ? MoodBloomColors.seed
                          : mb.textDim.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: i < filled
                        ? [
                            BoxShadow(
                              color: MoodBloomColors.seed.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
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
          children: [const _Spacer(), _digitKey(0), _backspaceKey()],
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

/// 88×88 dp cells with a 6 dp gutter put the physical hit area
/// comfortably above the WCAG 2.5.5 44×44 target. Same dimension is
/// shared by the digit keys and the blank spacer so the row alignment
/// stays grid-perfect.
const double _kKeypadCell = 88;
const double _kKeypadGutter = 6;

class _Spacer extends StatelessWidget {
  const _Spacer();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: _kKeypadCell + _kKeypadGutter * 2,
    height: _kKeypadCell + _kKeypadGutter * 2,
  );
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
    final tint = mb.text;
    final child = icon != null
        ? Icon(icon, color: foreground, size: 28)
        : Text(
            label!,
            style: MbFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          );
    // Material+InkWell with explicit high-alpha splash/highlight tints
    // so the press effect lands visibly on the cream/navy theme (the
    // default Material splash is washed out in this palette - same
    // story as the Settings tiles). A subtle background tile gives the
    // button an obvious "I am a button" affordance.
    return Semantics(
      label: semanticsLabel ?? label,
      button: true,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.all(_kKeypadGutter),
        child: SizedBox(
          width: _kKeypadCell,
          height: _kKeypadCell,
          child: Material(
            color: enabled ? mb.card : mb.card.withValues(alpha: 0.5),
            shape: CircleBorder(side: BorderSide(color: mb.line, width: 1)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              customBorder: const CircleBorder(),
              splashColor: tint.withValues(alpha: 0.35),
              highlightColor: tint.withValues(alpha: 0.18),
              splashFactory: InkRipple.splashFactory,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/intervention_dispatch.dart';
import '../controllers/intervention_controller.dart';
import '../widgets/dispatch_safe_defaults.dart';

/// Tier 1 surface — a 2-minute paced-breathing therapeutic deliverable.
///
/// This screen is **NOT** a placeholder. Per the engineer brief and
/// CLAUDE.md "Compassionate imperatives", the breathing exercise is the
/// whole Tier 1 dose. It contains:
///
///  * The dispatched body verbatim — already includes the curated quote
///    and `DisclaimerCopy.notificationFooter` (composed by the
///    dispatcher). Falls back to [DispatchSafeDefaults.tier1] when the
///    screen is opened without a dispatch (deep link).
///  * A visible mm:ss countdown (`_totalSeconds = 120`).
///  * A pulsing circle paced at 4-second inhale / 6-second exhale —
///    parasympathetic activation (Brown & Gerbarg 2005). The animation
///    is driven by a `TweenSequence` so the radius grows for the inhale
///    window (40%) and shrinks for the exhale window (60%), keeping the
///    visual cue and the text label in lockstep. The same controller
///    value picks the cue text ("Breathe in…" / "Breathe out…") at the
///    40% threshold.
///  * Two foot CTAs:
///      - "Done for now"  → `controller.complete()` + `context.pop()`
///        (the user engaged — no opt-out).
///      - "I'm okay"      → `controller.optOut()` + `context.pop()` via
///        the shared [InterventionOptOutButton].
///
/// On natural timer completion: light haptic, snackbar acknowledgement,
/// `controller.complete()`, auto-pop.
///
/// **Responsive layout:** phone (< 600 dp) keeps the stacked single
/// column. Tablet/desktop (>= 600 dp) splits into a two-column layout
/// — text + countdown + CTAs on the left, larger animated circle on
/// the right — capped at 960 dp so ultrawide doesn't stretch the line
/// length of the body copy.
///
/// **Accessibility:** the animated circle is wrapped in a `Semantics`
/// node with a single canonical label so a screen reader does not chase
/// every frame. The mm:ss countdown is announced as a live region but
/// throttled to the minute boundary — every-second updates would
/// overwhelm the AT focus stream.
class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({this.dispatch, super.key});

  final InterventionDispatch? dispatch;

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 120;

  /// 5s inhale + 5s hold + 8s exhale → 18s full cycle. Slower than the
  /// previous 14s pace after user feedback that the cue text changed
  /// too quickly to settle into; this lands close to the classic 4-7-8
  /// rhythm (Weil 2015) while keeping equal inhale/hold for the
  /// box-breathing feel.
  static const Duration _breathCycle = Duration(seconds: 18);

  /// Phase thresholds expressed as fractions of the cycle: inhale 0..5/18,
  /// hold 5/18..10/18, exhale 10/18..1.
  static const double _inhaleEnd = 5 / 18;
  static const double _holdEnd = 10 / 18;

  /// Phone/tablet breakpoint — mirrored from `_AppShell._tabletMin` in
  /// `app/router.dart` so the responsive behaviour is consistent
  /// app-wide.
  static const double _tabletMin = 600;

  late final AnimationController _breathController;
  late final Animation<double> _radius;
  Timer? _ticker;
  int _secondsRemaining = _totalSeconds;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(duration: _breathCycle, vsync: this)
      ..repeat();
    // Three-phase: grow 5s → hold 5s (flat) → shrink 8s. The flat hold
    // phase uses identical begin/end so the circle pauses at full size,
    // matching the "Hold" cue text. Weights match the seconds in
    // _breathCycle so the visual phase boundaries line up with the
    // _inhaleEnd / _holdEnd fractions exactly.
    _radius = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8,
      ),
    ]).animate(_breathController);
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    if (_secondsRemaining <= 1) {
      _ticker?.cancel();
      _secondsRemaining = 0;
      setState(() {});
      _onCompleted();
      return;
    }
    setState(() => _secondsRemaining -= 1);
  }

  Future<void> _onCompleted() async {
    if (_completed) return;
    _completed = true;
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Well done. Anytime you want to come back, we're here."),
      ),
    );
    ref.read(interventionControllerProvider.notifier).complete();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  String get _bodyText => widget.dispatch?.body ?? DispatchSafeDefaults.tier1;

  /// mm:ss formatted countdown. Used for both the visible label and the
  /// semantics label below — same source of truth.
  String _formattedClock(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(1, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Semantics text — refreshed every second but the `liveRegion` flag
  /// is gated to fire only on minute boundaries so screen readers do not
  /// stutter once per second.
  String _semanticsClock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m minutes $s seconds remaining';
  }

  /// Single done/close handler — used by the back button, the body
  /// "Done" CTA, and the natural timer completion. All three paths
  /// converge through the same controller call so opt-out and
  /// completion semantics stay consistent.
  void _onDone() {
    ref.read(interventionControllerProvider.notifier).complete();
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>();
    final bg = mb?.bg ?? theme.scaffoldBackgroundColor;
    final textColor = mb?.text ?? theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: bg,
      // Body-level back button (MbIconButton in a Row) matches the
      // Entry Detail screen pattern — no native AppBar. The "A breath
      // together" title moves into the responsive body variants below
      // so the H1 leads the content directly rather than sitting in
      // chrome above it.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _tabletMin;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MbIconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _onDone,
                            semanticLabel: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isWide
                            ? _buildWide(theme, textColor)
                            : _buildNarrow(theme, textColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNarrow(ThemeData theme, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'A breath together',
          style: MbFonts.fraunces(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            _bodyText,
            style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: _CountdownLabel(
            seconds: _secondsRemaining,
            color: textColor,
            semanticsLabel: _semanticsClock(_secondsRemaining),
            formatted: _formattedClock(_secondsRemaining),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(child: _BreathingCircle(animation: _radius, big: false)),
        const SizedBox(height: 12),
        _CueLabel(
          controller: _breathController,
          color: textColor,
          inhaleEnd: _inhaleEnd,
          holdEnd: _holdEnd,
        ),
        const SizedBox(height: 16),
        _DoneButton(onPressed: _onDone),
      ],
    );
  }

  /// Tablet/desktop layout — two-column. Left: body + countdown + cue
  /// + CTAs. Right: enlarged breathing circle (280 dp inside a 320 dp
  /// box).
  Widget _buildWide(ThemeData theme, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A breath together',
                style: MbFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  _bodyText,
                  style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
                ),
              ),
              const SizedBox(height: 28),
              _CountdownLabel(
                seconds: _secondsRemaining,
                color: textColor,
                semanticsLabel: _semanticsClock(_secondsRemaining),
                formatted: _formattedClock(_secondsRemaining),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: _CueLabel(
                  controller: _breathController,
                  color: textColor,
                  inhaleEnd: _inhaleEnd,
                  holdEnd: _holdEnd,
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: _DoneButton(onPressed: _onDone),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(child: _BreathingCircle(animation: _radius, big: true)),
      ],
    );
  }
}

/// Single bottom CTA. Tapping closes the screen with `complete()`
/// semantics — same as the back chevron and the natural timer
/// completion. The previous two-button row ("Done for now" + "I'm
/// okay") routed through different controller paths and felt
/// redundant; merging them keeps the user's intent simple.
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text("I'm done"),
    );
  }
}

/// mm:ss countdown — pulled out so both responsive variants compose the
/// same `Semantics(liveRegion: ...)` wrapper. The clock text is rendered
/// inside `ExcludeSemantics` so AT only sees the parent label.
class _CountdownLabel extends StatelessWidget {
  const _CountdownLabel({
    required this.seconds,
    required this.color,
    required this.semanticsLabel,
    required this.formatted,
  });

  final int seconds;
  final Color color;
  final String semanticsLabel;
  final String formatted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: seconds % 60 == 0,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Text(
          formatted,
          style: theme.textTheme.displayMedium?.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Animated breathing circle — square 220 / 320 box with the inner
/// disc scaled from 0.5 → 1.0 → 0.5 over the parent controller's cycle.
/// Extracted into a private widget so both responsive variants compose
/// the same `Semantics(label: 'Breathing rhythm guide')` node.
class _BreathingCircle extends StatelessWidget {
  const _BreathingCircle({required this.animation, required this.big});

  final Animation<double> animation;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outer = big ? 320.0 : 220.0;
    final inner = big ? 280.0 : 180.0;
    return Semantics(
      label: 'Breathing rhythm guide',
      container: true,
      excludeSemantics: true,
      child: Center(
        child: SizedBox(
          width: outer,
          height: outer,
          child: Center(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Transform.scale(
                  scale: animation.value,
                  child: Container(
                    width: inner,
                    height: inner,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// "Breathe in…" / "Hold…" / "Breathe out…" cue text — picks the phase
/// from `controller.value` using the inhale/hold/exhale thresholds. The
/// cue is wrapped in `ExcludeSemantics` so AT sees the canonical
/// "Breathing rhythm guide" anchor (one node up) instead of the
/// per-frame cue.
class _CueLabel extends StatelessWidget {
  const _CueLabel({
    required this.controller,
    required this.color,
    required this.inhaleEnd,
    required this.holdEnd,
  });

  final AnimationController controller;
  final Color color;
  final double inhaleEnd;
  final double holdEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final v = controller.value;
          final label = v < inhaleEnd
              ? 'Breathe in…'
              : (v < holdEnd ? 'Hold…' : 'Breathe out…');
          return Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/intervention_dispatch.dart';
import '../controllers/intervention_controller.dart';
import '../widgets/dispatch_safe_defaults.dart';

/// Tier 1 surface - a 2-minute paced-breathing therapeutic deliverable,
/// presented as a modal (bottom sheet on phone, dialog on tablet+) per
/// the v1.6 prototype's `ModalFrame`.
///
/// Use [BreathingSheet.show] to present it. The body content lives in
/// [BreathingView]; the launcher supplies the modal chrome.
class BreathingSheet {
  const BreathingSheet._();

  /// Opens the breathing modal. [dispatch] carries the curated quote +
  /// disclaimer footer when the surface was reached from an
  /// intervention banner / notification; null falls back to
  /// [DispatchSafeDefaults.tier1] for the self-initiated "Take a
  /// breath" path.
  static Future<void> show(
    BuildContext context, {
    InterventionDispatch? dispatch,
  }) {
    return MbModalSheet.show<void>(
      context,
      builder: (ctx) => BreathingView(
        dispatch: dispatch,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

/// The breathing exercise body. Contains:
///
///  * The dispatched body verbatim (curated quote + disclaimer footer),
///    falling back to [DispatchSafeDefaults.tier1] when self-initiated.
///  * A visible mm:ss countdown (`_totalSeconds = 120`).
///  * A pulsing circle paced 5s inhale / 5s hold / 8s exhale.
///  * An "I'm done" CTA. All exit paths run [InterventionController.complete]
///    then [onClose].
///
/// On natural timer completion: light haptic, snackbar acknowledgement,
/// `controller.complete()`, then [onClose].
class BreathingView extends ConsumerStatefulWidget {
  const BreathingView({this.dispatch, required this.onClose, super.key});

  final InterventionDispatch? dispatch;

  /// Invoked to dismiss the surface. The modal launcher passes
  /// `() => Navigator.of(context).pop()`.
  final VoidCallback onClose;

  @override
  ConsumerState<BreathingView> createState() => _BreathingViewState();
}

class _BreathingViewState extends ConsumerState<BreathingView>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 120;

  /// 5s inhale + 5s hold + 8s exhale → 18s full cycle.
  static const Duration _breathCycle = Duration(seconds: 18);
  static const double _inhaleEnd = 5 / 18;
  static const double _holdEnd = 10 / 18;

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
    widget.onClose();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  String get _bodyText => widget.dispatch?.body ?? DispatchSafeDefaults.tier1;

  String _formattedClock(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(1, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _semanticsClock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m minutes $s seconds remaining';
  }

  /// Single done/close handler - used by the header close icon, the
  /// body "I'm done" CTA, and natural timer completion. All converge
  /// through the same controller `complete()` call.
  void _onDone() {
    ref.read(interventionControllerProvider.notifier).complete();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;

    return MbModalScaffold(
      title: 'Take a breath',
      onClose: _onDone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: MoodBloomSpacing.sm),
          Text(
            _bodyText,
            textAlign: TextAlign.center,
            style: MbFonts.nunito(fontSize: 13, height: 1.5, color: mb.textDim),
          ),
          const SizedBox(height: 24),
          _BreathingCircle(
            controller: _breathController,
            scale: _radius,
            inhaleEnd: _inhaleEnd,
            holdEnd: _holdEnd,
          ),
          const SizedBox(height: 24),
          _CountdownLabel(
            seconds: _secondsRemaining,
            color: mb.text,
            semanticsLabel: _semanticsClock(_secondsRemaining),
            formatted: _formattedClock(_secondsRemaining),
          ),
          const SizedBox(height: 4),
          Text(
            'remaining',
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
          const SizedBox(height: 24),
          MbGhostButton(
            label: "I'm done",
            fullWidth: false,
            onPressed: _onDone,
          ),
        ],
      ),
    );
  }
}

/// mm:ss countdown in serif. The clock text is rendered inside
/// `ExcludeSemantics` so AT only sees the parent `liveRegion` label
/// (throttled to the minute boundary).
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
    return Semantics(
      liveRegion: seconds % 60 == 0,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Text(
          formatted,
          style: MbFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Breathing rhythm guide - a 200 dp radial-gradient disc (soft-green
/// fading to the page background) with a seed-coloured ring that scales
/// with the breath cycle, and the current phase word ("Inhale" / "Hold"
/// / "Exhale") centred in serif. Ports the prototype's breathing circle;
/// the ring scale is driven by the live animation so the visual paces
/// the user's breath rather than sitting static.
class _BreathingCircle extends StatelessWidget {
  const _BreathingCircle({
    required this.controller,
    required this.scale,
    required this.inhaleEnd,
    required this.holdEnd,
  });

  final AnimationController controller;
  final Animation<double> scale;
  final double inhaleEnd;
  final double holdEnd;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Semantics(
      label: 'Breathing rhythm guide',
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static radial-gradient backdrop: soft-green core fading to
            // the page background by ~70%.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [MoodBloomColors.softGreen, mb.bg],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: const SizedBox(width: 200, height: 200),
            ),
            // Seed ring that scales with the breath (inhale grows it,
            // exhale shrinks it).
            AnimatedBuilder(
              animation: scale,
              builder: (context, _) {
                final d = 100 + scale.value * 60; // 130 .. 160 dp
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MoodBloomColors.seed, width: 2),
                  ),
                );
              },
            ),
            // Phase word, centred.
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final v = controller.value;
                final label = v < inhaleEnd
                    ? 'Inhale'
                    : (v < holdEnd ? 'Hold' : 'Exhale');
                return Text(
                  label,
                  style: MbFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: MoodBloomColors.seedDark,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

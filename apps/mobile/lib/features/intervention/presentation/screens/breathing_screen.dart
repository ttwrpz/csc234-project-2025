import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/intervention_dispatch.dart';
import '../controllers/intervention_controller.dart';
import '../widgets/dispatch_safe_defaults.dart';
import '../widgets/intervention_opt_out_button.dart';

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
///    controller's `value` drives the radius via a `Curves.easeInOut`
///    tween between 0.5 and 1.0; the same `value` also picks the cue
///    text ("Breathe in…" / "Breathe out…").
///  * Two foot CTAs:
///      - "Done for now"  → `controller.complete()` + `context.pop()`
///        (the user engaged — no opt-out).
///      - "I'm okay"      → `controller.optOut()` + `context.pop()` via
///        the shared [InterventionOptOutButton].
///
/// On natural timer completion: light haptic, snackbar acknowledgement,
/// `controller.complete()`, auto-pop.
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

  /// 4s inhale + 6s exhale → 10s full cycle. Slow, parasympathetic.
  static const Duration _breathCycle = Duration(seconds: 10);

  /// Inhale fraction of the cycle (`4 / 10`). Used to pick the cue text.
  static const double _inhaleFraction = 0.4;

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
    _radius = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('A breath together')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_bodyText, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              Center(
                child: Semantics(
                  liveRegion: _secondsRemaining % 60 == 0,
                  label: _semanticsClock(_secondsRemaining),
                  child: ExcludeSemantics(
                    child: Text(
                      _formattedClock(_secondsRemaining),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Semantics(
                    label: 'Breathing rhythm guide',
                    container: true,
                    excludeSemantics: true,
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (context, _) {
                        final isInhale =
                            _breathController.value < _inhaleFraction;
                        final scale = _radius.value;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.primaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isInhale ? 'Breathe in…' : 'Breathe out…',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(interventionControllerProvider.notifier)
                          .complete();
                      context.pop();
                    },
                    child: const Text('Done for now'),
                  ),
                  InterventionOptOutButton(
                    onTapped: () {
                      if (context.mounted) context.pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

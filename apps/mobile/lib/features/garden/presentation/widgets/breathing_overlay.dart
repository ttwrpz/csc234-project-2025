import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Full-screen 4-7-8 breathing modal opened from the cheer-up banner.
///
/// Shape spec (locked in the brief):
///  * Phase order: in (4 s) → hold (7 s) → out (8 s) → repeat.
///  * Cycle counter increments each time the loop returns to "in".
///  * Two concentric `AnimatedContainer`s: the outer (radial primary
///    gradient) animates 240↔120 dp; the inner (white ring) follows.
///    Animation duration is the *current phase's duration* (so the
///    inhale takes 4 s, the hold doesn't visibly resize but holds at
///    the inhaled size, the exhale takes 8 s).
///  * Caption + Done button at the bottom.
///
/// Show via `showDialog(context: ..., builder: (_) => const BreathingOverlay())`.
class BreathingOverlay extends StatefulWidget {
  const BreathingOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useSafeArea: false,
      builder: (_) => const BreathingOverlay(),
    );
  }

  @override
  State<BreathingOverlay> createState() => _BreathingOverlayState();
}

enum _BreathPhase { inBreath, hold, outBreath }

class _BreathingOverlayState extends State<BreathingOverlay> {
  _BreathPhase _phase = _BreathPhase.inBreath;
  int _cycle = 0;
  Timer? _timer;

  static const _phaseDurations = <_BreathPhase, Duration>{
    _BreathPhase.inBreath: Duration(seconds: 4),
    _BreathPhase.hold: Duration(seconds: 7),
    _BreathPhase.outBreath: Duration(seconds: 8),
  };

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    final dur = _phaseDurations[_phase]!;
    _timer = Timer(dur, () {
      if (!mounted) return;
      setState(() {
        switch (_phase) {
          case _BreathPhase.inBreath:
            _phase = _BreathPhase.hold;
          case _BreathPhase.hold:
            _phase = _BreathPhase.outBreath;
          case _BreathPhase.outBreath:
            _phase = _BreathPhase.inBreath;
            _cycle += 1;
        }
      });
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dur = _phaseDurations[_phase]!;
    final size = _phase == _BreathPhase.outBreath ? 120.0 : 240.0;
    final label = switch (_phase) {
      _BreathPhase.inBreath => 'Breathe in…',
      _BreathPhase.hold => 'Hold…',
      _BreathPhase.outBreath => 'Breathe out…',
    };

    // Coral-on-cream "5A3A2E" reads on the prototype's softGreen→coral
    // radial bg; mirror it here.
    const captionColor = Color(0xFF5A3A2E);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [MoodBloomColors.softGreen, MoodBloomColors.coral],
            radius: 1.1,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top bar: label chip + close button.
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(
                          MoodBloomSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '4-7-8 breathing',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: captionColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Close breathing exercise',
                      button: true,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(
                          MoodBloomSpacing.radiusFull,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(
                              MoodBloomSpacing.radiusFull,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: captionColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Center content.
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: dur,
                            curve: Curves.easeInOut,
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primary.withValues(alpha: 0.8),
                                  primary.withValues(alpha: 0.27),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.33),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: dur,
                            curve: Curves.easeInOut,
                            width: size - 40,
                            height: size - 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          Text(
                            label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              shadows: const [
                                Shadow(
                                  color: Color(0x33000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Cycle ${_cycle + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: captionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "If it helps, keep going. If not, that's okay too.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: captionColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Done button anchored near the bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: MbPrimaryButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

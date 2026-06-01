import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/intervention/presentation/controllers/intervention_controller.dart';
import '../features/intervention/presentation/widgets/intervention_banner.dart';

/// App-level wrapper that overlays the [InterventionBanner] above the
/// active route's content. Attached at `MaterialApp.router(builder:)` in
/// `bootstrap.dart` so the banner can appear regardless of which tab
/// the user is on (Garden / History / Patterns / Settings - all four
/// host the banner once the controller reaches [InterventionPending]).
///
/// The banner is anchored at the bottom of the screen, inside the
/// safe-area-aware [InterventionBanner] widget. It sits in a [Stack]
/// above the routed `child` - when the controller is idle, the banner
/// collapses to `SizedBox.shrink()` (zero hit area) so the user
/// interacts with the underlying screen normally.
///
/// **Why a builder + Stack instead of nesting inside the shell route?**
/// The intervention banner must be visible on the auth gates and
/// pre-shell screens too (e.g., the biometric gate); wiring it inside
/// the `StatefulShellRoute` would hide it on those routes. The
/// dispatcher only fires after sign-in, but the host being above the
/// router means the surface is always present in the tree, ready to
/// render the moment the controller transitions to pending.
class InterventionBannerHost extends ConsumerWidget {
  const InterventionBannerHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only include the Positioned banner when there's a pending
    // intervention. Rendering a 0-height Positioned (the idle state's
    // SizedBox.shrink) caused "Cannot hit test a render box with no
    // size" assertions that swallowed taps app-wide.
    final state = ref.watch(interventionControllerProvider);
    final hasPending = state is InterventionPending;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (hasPending)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: InterventionBanner(),
          ),
      ],
    );
  }
}

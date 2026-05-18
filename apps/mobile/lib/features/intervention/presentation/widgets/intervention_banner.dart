import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../pattern_engine/domain/entities/tier.dart';
import '../controllers/intervention_controller.dart';
import 'intervention_opt_out_button.dart';

/// Bottom-anchored banner that appears whenever
/// [interventionControllerProvider] has emitted [InterventionPending].
///
/// Wrapped in a [Dismissible] so a horizontal swipe-out is treated as
/// opt-out (opting out advances the cooldown anchor so the system does
/// not re-nag). Tap "Open" to navigate
/// to the corresponding tier screen via a typed named route; the
/// dispatch is forwarded as `extra` so the screen can render the body
/// verbatim instead of re-deriving it.
///
/// Tier 3 dispatches paint the banner card with `colorScheme.errorContainer`
/// — visually distinct but compassionate (no red flashing / no shake
/// animation). The CLAUDE.md "No streak-shaming" rule extends to crisis
/// surfaces: prominence is appropriate, alarm is not.
class InterventionBanner extends ConsumerWidget {
  const InterventionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interventionControllerProvider);
    if (state is! InterventionPending) {
      return const SizedBox.shrink();
    }
    final dispatch = state.dispatch;
    final theme = Theme.of(context);
    final isTier3 = dispatch.tier == Tier.three;
    final cardColor = isTier3
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fgColor = isTier3
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    // Truncate to the first sentence (rough heuristic: stop at the
    // first `.`, `?`, or `!`) plus an ellipsis if the body continues.
    final preview = _previewBody(dispatch.body);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        // Cap the banner width on tablet/desktop so it doesn't stretch the
        // full viewport. 640 dp matches the analytics card width and keeps
        // the banner visually balanced on wide layouts.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Dismissible(
              key: ValueKey('intervention-banner-${dispatch.dispatchId}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) async {
                await ref
                    .read(interventionControllerProvider.notifier)
                    .optOut();
              },
              child: Material(
                color: cardColor,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InterventionOptOutButton(),
                          const SizedBox(width: 8),
                          FilledButton(
                            // pushNamed (not goNamed) so the intervention
                            // route sits on top of the shell rather than
                            // replacing it; otherwise the redirect chain
                            // re-evaluates and can bounce us back to /home.
                            onPressed: () => context.pushNamed(
                              _routeNameFor(dispatch.tier),
                              extra: dispatch,
                            ),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _previewBody(String body) {
    // Stop at the first sentence-ending punctuation; keep the punctuation
    // and append an ellipsis to signal there's more behind the banner.
    for (var i = 0; i < body.length; i++) {
      final ch = body[i];
      if (ch == '.' || ch == '?' || ch == '!') {
        final head = body.substring(0, i + 1);
        return i + 1 < body.length ? '$head…' : head;
      }
    }
    return body;
  }

  /// Maps the dispatched tier to its named route. Kept private here so
  /// the banner is the single source of truth — the screens never
  /// re-derive the mapping.
  static String _routeNameFor(Tier tier) => switch (tier) {
    Tier.one => 'intervention.breathing',
    Tier.two => 'intervention.journal',
    Tier.three => 'intervention.crisis',
  };
}

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart' show routerProvider;
import '../../../disclaimer/domain/disclaimer_copy.dart';
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

    // The dispatcher composes `body` as "<quote>\n\n<disclaimer footer>".
    // Split them so the actionable message reads prominently and the
    // medical disclaimer drops to a small, dim footnote - kept for
    // compliance (CLAUDE.md locked rule) but no longer competing with
    // the CTA for attention ("show it less intrusively").
    final footerIdx = dispatch.body.indexOf(DisclaimerCopy.notificationFooter);
    final messageText = footerIdx >= 0
        ? dispatch.body.substring(0, footerIdx).trim()
        : dispatch.body;
    final hasDisclaimer = footerIdx >= 0;

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
                borderRadius: BorderRadius.circular(
                  MoodBloomSpacing.radiusCardLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(MoodBloomSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        // maxLines:3 + ellipsis keeps the Tier 1/2 quote
                        // wrap natural without truncating to a single
                        // sentence. DO NOT revert.
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: MbFonts.nunito(
                          fontSize: 14,
                          height: 1.55,
                          color: fgColor,
                        ),
                      ),
                      if (hasDisclaimer) ...[
                        const SizedBox(height: 6),
                        Text(
                          DisclaimerCopy.notificationFooter,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MbFonts.nunito(
                            fontSize: 10,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                            color: fgColor.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                      const SizedBox(height: MoodBloomSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InterventionOptOutButton(),
                          const SizedBox(width: 8),
                          // Navigate via the GoRouter instance from the
                          // provider, NOT `context.pushNamed`. This banner
                          // is hosted in `MaterialApp.router(builder:)` -
                          // ABOVE the Router's Navigator - so a context
                          // lookup can't find the InheritedGoRouter and the
                          // push silently no-ops (the "Open does nothing"
                          // bug). The provider gives the live router
                          // directly. pushNamed (not goNamed) keeps the
                          // tier route on top of the shell.
                          MbPrimaryButton(
                            label: 'Open',
                            fullWidth: false,
                            onPressed: () => ref
                                .read(routerProvider)
                                .pushNamed(
                                  _routeNameFor(dispatch.tier),
                                  extra: dispatch,
                                ),
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

  /// Maps the dispatched tier to its named route. Kept private here so
  /// the banner is the single source of truth — the screens never
  /// re-derive the mapping.
  static String _routeNameFor(Tier tier) => switch (tier) {
    Tier.one => 'intervention.breathing',
    Tier.two => 'intervention.journal',
    Tier.three => 'intervention.crisis',
  };
}

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
/// - visually distinct but compassionate (no red flashing / no shake
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

    // The dispatcher composes `body` as "<quote>\n\n<disclaimer footer>".
    // Split them so the actionable message reads prominently and the
    // medical disclaimer drops to a small, dim footnote - kept for
    // compliance (CLAUDE.md locked rule) but no longer competing with
    // the CTA for attention.
    final footerIdx = dispatch.body.indexOf(DisclaimerCopy.notificationFooter);
    final messageText = footerIdx >= 0
        ? dispatch.body.substring(0, footerIdx).trim()
        : dispatch.body;
    final hasDisclaimer = footerIdx >= 0;

    void openTier() {
      // Navigate via the GoRouter instance from the provider, NOT
      // `context.pushNamed`. This banner is hosted in
      // `MaterialApp.router(builder:)` - ABOVE the Router's Navigator - so a
      // context lookup can't find the InheritedGoRouter and the push
      // silently no-ops. pushNamed keeps the tier route on top.
      ref
          .read(routerProvider)
          .pushNamed(_routeNameFor(dispatch.tier), extra: dispatch);
      // Dismiss the banner as the surface opens so it doesn't linger over
      // the now-full-screen tier screen.
      ref.read(interventionControllerProvider.notifier).complete();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        // Cap the banner width on tablet/desktop so it doesn't stretch the
        // full viewport. 640 dp matches the analytics card width.
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
              // Dark-glass treatment matching the saved-mood MbAppToast so
              // the intervention reads as the same toast family. Keeps the
              // Open + opt-out actions + disclaimer the tiers require.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: const Color.fromARGB(235, 20, 24, 30),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(MoodBloomSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 26,
                              width: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4A78C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const MbBrandSvg(
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _titleFor(dispatch.tier),
                                style: MbFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          messageText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: MbFonts.nunito(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.9),
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
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        const SizedBox(height: MoodBloomSpacing.md),
                        // Equal-width action buttons - each fills half the
                        // row so "I'm okay" and "Open" read as a matched pair
                        // rather than two differently-sized chips.
                        Row(
                          children: [
                            const Expanded(child: InterventionOptOutButton()),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MbPrimaryButton(
                                label: 'Open',
                                onPressed: openTier,
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
      ),
    );
  }

  /// Title shown in the toast header per tier - mirrors the FCM payload
  /// titles so push + in-app read consistently.
  static String _titleFor(Tier tier) => switch (tier) {
    Tier.one => 'Take a breath?',
    Tier.two => 'A few quiet words?',
    Tier.three => "We're here",
  };

  /// Maps the dispatched tier to its named route. Kept private here so
  /// the banner is the single source of truth - the screens never
  /// re-derive the mapping.
  static String _routeNameFor(Tier tier) => switch (tier) {
    Tier.one => 'intervention.breathing',
    Tier.two => 'intervention.journal',
    Tier.three => 'intervention.crisis',
  };
}

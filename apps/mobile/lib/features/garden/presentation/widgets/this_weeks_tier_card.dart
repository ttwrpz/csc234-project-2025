import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tokens/data/providers.dart';
import '../../../tokens/presentation/controllers/token_visibility_controller.dart';
import '../../domain/entities/plant_tier.dart';

/// Full MbCard rendering the active `THIS WEEK'S TIER`. Left side
/// stacks an uppercase section label + the tier name in serif; right
/// side carries a soft-green token pill (icon + balance + "tokens"
/// suffix).
///
/// The token pill collapses when the user has hidden the token balance
/// via Settings, OR when the balance has not yet streamed in - the
/// left-side tier name reads on its own in that case.
class ThisWeeksTierCard extends ConsumerWidget {
  const ThisWeeksTierCard({super.key, required this.tier});

  /// Tier derived from the week's Garden Health EWMA. The serif name
  /// + token pill both render against the same MbCard surface.
  final PlantTier tier;

  /// Human-readable tier name for the serif row. Matches the
  /// CLAUDE.md "Storm Season" capitalisation rule.
  static String nameFor(PlantTier tier) => switch (tier) {
    PlantTier.flourishing => 'Flourishing',
    PlantTier.thriving => 'Thriving',
    PlantTier.resting => 'Resting',
    PlantTier.weathering => 'Weathering',
    PlantTier.stormSeason => 'Storm Season',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final visible = ref.watch(tokenVisibilityProvider);
    final balance = ref.watch(tokenBalanceStreamProvider).value;
    final showToken = visible && balance != null;

    return Semantics(
      label: "This week's tier: ${nameFor(tier)}",
      container: true,
      child: MbCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const MbSectionLabel("THIS WEEK'S TIER"),
                  const SizedBox(height: 4),
                  Text(
                    nameFor(tier),
                    style: MbFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (showToken) ...<Widget>[
              const SizedBox(width: 12),
              _GreenTokenPill(balance: balance.balance),
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft-green pill mirroring the prototype's `THIS WEEK'S TIER` card
/// token chip - flower icon + balance + "tokens" suffix. Sits inside
/// the card alongside the tier name; the standalone `TokenBalanceChip`
/// elsewhere keeps its neutral card-on-bg styling so the two reads
/// don't fight each other on the home screen.
class _GreenTokenPill extends StatelessWidget {
  const _GreenTokenPill({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MoodBloomColors.seed.withValues(alpha: 0.18)
        : MoodBloomColors.softGreen;
    final fg = isDark ? const Color(0xFFCDE8DA) : MoodBloomColors.seedDark;
    final label = balance == 1 ? '1 token' : '$balance tokens';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.local_florist, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: MbFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

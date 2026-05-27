import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Soft AI-tinted card carrying a non-clinical, no-fix-your-mood
/// nudge. Reads from the top row down: `auto_awesome` glyph + `GENTLE
/// NUDGE` section label + confidence badge, followed by the body copy,
/// then the locked medical-disclaimer footer.
///
/// Pure presentation - the caller supplies the body string + confidence
/// bucket. Defaults render a compassionate generic phrase suitable for
/// users with no entries yet; once a nudge service ships, the caller
/// can swap in personalised copy + a higher confidence level.
class GentleNudgeCard extends StatelessWidget {
  const GentleNudgeCard({
    super.key,
    this.body = _defaultBody,
    this.confidence = MbConfidenceLevel.low,
  });

  /// Body copy. Must follow the project's copy rules - no clinical
  /// language, no fix-your-mood verbs, no streak-shaming.
  final String body;

  /// Confidence bucket displayed in the top-right pill.
  final MbConfidenceLevel confidence;

  /// Compassionate fallback used when the caller has no personalised
  /// nudge to surface. Soft imperative ("if it helps"), no clinical
  /// language, no streak-shaming.
  static const String _defaultBody =
      'If it helps, notice one moment that felt steady this week. '
      'Tiny anchors count.';

  /// Locked medical-disclaimer footer per CLAUDE.md.
  static const String _disclaimer =
      'MoodBloom is not a medical device. Not a substitute for professional care.';

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: mb.aiBg,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        border: Border.all(color: mb.aiBd),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(child: MbSectionLabel('GENTLE NUDGE')),
              MbConfidenceBadge(level: confidence),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: MbFonts.nunito(
              fontSize: 14,
              color: mb.text,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _disclaimer,
            style: MbFonts.nunito(
              fontSize: 11,
              color: mb.textDim,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

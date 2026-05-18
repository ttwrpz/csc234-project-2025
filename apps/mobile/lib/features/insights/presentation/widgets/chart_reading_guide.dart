import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// "What am I looking at?" glossary card.
///
/// Renders three plain-English lines that translate the chart's
/// technical features (solid line / dashed rolling rhythm / coloured
/// tier bands) into compassionate copy. Wraps the body in an
/// [ExpansionTile] on phone so it stays collapsed by default and
/// saves vertical real estate; tablet + desktop pass
/// `alwaysExpanded: true` to drop the disclosure chevron and show
/// the body as a static [Column] inside a card.
///
/// Copy obeys CLAUDE.md "no clinical language" + "no streak-shaming"
/// rules. The phrase "rolling rhythm" replaces the technical EWMA
/// term so the academic vocabulary stays in the spec, not the UI.
class ChartReadingGuide extends StatelessWidget {
  const ChartReadingGuide({super.key, this.alwaysExpanded = false});

  /// When `true` the body renders unconditionally (used on tablet and
  /// desktop left-rail). When `false` an [ExpansionTile] gates the body
  /// behind a tap (phone default).
  final bool alwaysExpanded;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final titleStyle = MbFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: mb.text,
    );

    if (alwaysExpanded) {
      return Semantics(
        container: true,
        label: 'What am I looking at? Chart reading guide.',
        child: MbCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What am I looking at?', style: titleStyle),
              const SizedBox(height: 8),
              const _GuideBody(),
            ],
          ),
        ),
      );
    }

    return MbCard(
      // ExpansionTile draws its own padding — strip the card's default
      // so the tile fills the card cleanly.
      padding: EdgeInsets.zero,
      child: Theme(
        // Strip the underlying ListTile divider so the closed/open
        // states share the same outline as every other MbCard.
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Semantics(
            // Without this label, TalkBack reads the tile as just
            // "What am I looking at?" without indicating it expands.
            label: 'What am I looking at? Tap to learn how to read the chart.',
            child: Text('What am I looking at?', style: titleStyle),
          ),
          iconColor: mb.textDim,
          collapsedIconColor: mb.textDim,
          children: const [_GuideBody()],
        ),
      ),
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final body = MbFonts.nunito(fontSize: 13, color: mb.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bullet(
          context,
          'The solid line is the mood you have been logging — higher is '
          'brighter, lower is rainier. Empty spots are quiet days, never '
          'a streak break.',
          style: body,
        ),
        const SizedBox(height: 8),
        _bullet(
          context,
          'The dashed line is the rolling rhythm — a weighted average '
          'that smooths the daily wobbles so a single rough day does '
          'not tilt it.',
          style: body,
        ),
        const SizedBox(height: 8),
        _bullet(
          context,
          'The soft coloured bands are the garden tiers. Every tier is '
          'alive — even Storm Season is sheltered, never withered.',
          style: body,
        ),
      ],
    );
  }

  static Widget _bullet(
    BuildContext context,
    String text, {
    required TextStyle style,
  }) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: mb.textDim,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

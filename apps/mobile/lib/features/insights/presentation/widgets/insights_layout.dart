import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// HB-009 Decision B — adaptive layout for the Insights screen.
///
/// The screen feeds five named slots into this wrapper:
///   * [header] — title + subtitle (always full-width at the top).
///   * [readingGuide] — the "What am I looking at?" affordance.
///   * [windowChips] — 7d / 14d / 30d segmented selector.
///   * [chart] — the chart card (mood-score timeline + marker band).
///   * [tierLegend] — persistent legend of the 5 plant tiers.
///   * [recentTriggers] — last 5 trigger days.
///
/// The wrapper picks the column arrangement based on the available
/// width. Below 600 dp everything stacks single-column. From 600..899
/// dp two columns flow above the chart, with the chart spanning the
/// full width below them. From 900 dp up three columns: left rail
/// (guide + chips), centre (chart), right rail (legend + triggers).
///
/// The disclaimer ack gate sits OUTSIDE this wrapper in
/// `insights_screen.dart` — the wrapper renders the same children in
/// the pre-ack state too (the caller short-circuits to a `_PreAckCard`
/// in the chart slot), so the layout switch is the single source of
/// truth.
class InsightsLayout extends StatelessWidget {
  const InsightsLayout({
    super.key,
    required this.header,
    required this.readingGuide,
    required this.windowChips,
    required this.chart,
    required this.tierLegend,
    required this.recentTriggers,
  });

  /// Phone vs tablet breakpoint. Matches the shell in
  /// `apps/mobile/lib/app/router.dart`.
  static const double phoneTabletBreakpoint = 600;

  /// Tablet vs desktop breakpoint. Matches the shell in
  /// `apps/mobile/lib/app/router.dart`.
  static const double tabletDesktopBreakpoint = 900;

  final Widget header;
  final Widget readingGuide;
  final Widget windowChips;
  final Widget chart;
  final Widget tierLegend;
  final Widget recentTriggers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= tabletDesktopBreakpoint) return _buildDesktop();
        if (w >= phoneTabletBreakpoint) return _buildTablet();
        return _buildPhone();
      },
    );
  }

  /// Single-column scroll. Order chosen so first-time visitors meet the
  /// "What am I looking at?" tile before the chart pulls them in.
  Widget _buildPhone() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
      children: [
        header,
        const SizedBox(height: MoodBloomSpacing.md),
        readingGuide,
        const SizedBox(height: MoodBloomSpacing.md),
        windowChips,
        const SizedBox(height: MoodBloomSpacing.md),
        chart,
        const SizedBox(height: MoodBloomSpacing.md),
        tierLegend,
        const SizedBox(height: MoodBloomSpacing.md),
        recentTriggers,
      ],
    );
  }

  /// Two columns above the chart, chart spans the width below them. The
  /// outer scroll is a single [SingleChildScrollView] so the right rail
  /// never gets its own scrollable — nested scrolls are a tablet a11y
  /// regression we never want here.
  ///
  /// We avoid [IntrinsicHeight] because Flutter's `LayoutBuilder`
  /// upstream rejects intrinsic-dimension queries. Each rail is a
  /// `Column` and the [Row] aligns them at the top — the cards size
  /// themselves naturally; the two rails can have different heights
  /// without affecting the chart slot underneath.
  Widget _buildTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: MoodBloomSpacing.md),
          // Two columns above the chart.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    readingGuide,
                    const SizedBox(height: MoodBloomSpacing.md),
                    windowChips,
                  ],
                ),
              ),
              const SizedBox(width: MoodBloomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tierLegend,
                    const SizedBox(height: MoodBloomSpacing.md),
                    recentTriggers,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoodBloomSpacing.md),
          chart,
        ],
      ),
    );
  }

  /// Desktop: window chips span full width directly under the header
  /// (mirroring the Patterns/Analytics screen), then the chart, then
  /// the three remaining rail cards in a 3-column row below.
  Widget _buildDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: MoodBloomSpacing.md),
          windowChips,
          const SizedBox(height: MoodBloomSpacing.md),
          chart,
          const SizedBox(height: MoodBloomSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: readingGuide),
              const SizedBox(width: MoodBloomSpacing.md),
              Expanded(child: tierLegend),
              const SizedBox(width: MoodBloomSpacing.md),
              Expanded(child: recentTriggers),
            ],
          ),
        ],
      ),
    );
  }
}

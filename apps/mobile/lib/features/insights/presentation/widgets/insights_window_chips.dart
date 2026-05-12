import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/insight_window.dart';

/// Segmented 7d / 14d / 30d chip selector for the Insights window.
/// Visual treatment mirrors the existing `MoodWindowSelector` on the
/// analytics screen so the two surfaces feel like one read-mode.
class InsightsWindowChips extends StatelessWidget {
  const InsightsWindowChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final InsightWindowPreset value;
  final ValueChanged<InsightWindowPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return MbSegmentedToggle<InsightWindowPreset>(
      value: value,
      onChanged: onChanged,
      items: const [
        MbSegmentedItem(value: InsightWindowPreset.week, label: '7d'),
        MbSegmentedItem(value: InsightWindowPreset.fortnight, label: '14d'),
        MbSegmentedItem(value: InsightWindowPreset.month, label: '30d'),
      ],
    );
  }
}

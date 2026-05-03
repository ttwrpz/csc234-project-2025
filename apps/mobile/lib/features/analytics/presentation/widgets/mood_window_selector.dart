import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pill-segmented selector bound to a [MoodWindow]. Restyled to wrap the
/// shared [MbSegmentedToggle] so the analytics screen visually matches
/// the History list/calendar swap and the prototype.
///
/// Public API ([value], [onChanged]) is preserved so existing call sites
/// keep compiling unchanged.
class MoodWindowSelector extends StatelessWidget {
  const MoodWindowSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MoodWindow value;
  final ValueChanged<MoodWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mood chart window selector',
      child: MbSegmentedToggle<MoodWindow>(
        items: const [
          MbSegmentedItem(value: MoodWindow.week, label: '7 days'),
          MbSegmentedItem(value: MoodWindow.month, label: '30 days'),
          MbSegmentedItem(value: MoodWindow.quarter, label: '90 days'),
        ],
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

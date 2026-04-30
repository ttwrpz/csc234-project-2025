import 'package:analytics_pkg/analytics_pkg.dart';
import 'package:flutter/material.dart';

/// Segmented button bound to a [MoodWindow]. Extracted so the analytics
/// screen body stays focused and the selector can be reused if Settings ever
/// exposes a default-window preference.
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
      child: SegmentedButton<MoodWindow>(
        segments: [
          for (final w in MoodWindow.values)
            ButtonSegment<MoodWindow>(
              value: w,
              label: Text(w.label),
              tooltip: 'Show last ${w.days} days',
            ),
        ],
        selected: {value},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          onChanged(selection.first);
        },
        showSelectedIcon: false,
      ),
    );
  }
}

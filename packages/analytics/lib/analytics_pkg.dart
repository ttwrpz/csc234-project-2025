/// MoodBloom analytics package — pure-Flutter re-exports of the line chart
/// widget and its supporting types.
///
/// This package MUST NOT depend on `apps/mobile` (circular layer violation),
/// nor on `packages/design_system`. Callers pass colors in via
/// [MoodLineChartTheme].
library;

export 'src/chart_mood_category.dart';
export 'src/mood_line_chart.dart';
export 'src/mood_line_chart_theme.dart';
export 'src/mood_point.dart';
export 'src/mood_window.dart';

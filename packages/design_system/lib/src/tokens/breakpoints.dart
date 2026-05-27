/// Centralised breakpoint constants for the v1.6 UI redesign.
///
/// Replaces scattered literals (`< 600`, `< 720`, `< 900`, `< 1080`)
/// across screens with a single source of truth. App-shell + most
/// screens use the `phone / tablet / desktop` triplet; screens with
/// their own internal layout breakpoint (Garden, Log Mood, History
/// calendar, Insights chart) add a `*Wide` constant.
abstract final class MbBreakpoints {
  const MbBreakpoints._();

  // App-shell boundaries (used by `_AppShell` and modal presentation).
  /// Phone is anything `< phone`. Tablet is `[phone, desktop)`.
  static const double phone = 600;

  /// Desktop is anything `>= desktop` (sidebar nav unlocks at this width).
  static const double desktop = 900;

  // Screen-internal layout boundaries.
  /// Garden home unlocks 2-column layout at this width.
  static const double homeWide = 720;

  /// Garden home applies the desktop content cap at this width.
  static const double homeDesktop = 1080;

  /// Log mood form switches to 2-column at this width.
  static const double logMoodWide = 720;

  /// History calendar splits into calendar + side panel at this width.
  static const double historySidePanel = 720;

  /// Insights body switches from single column to 2-column above the
  /// chart at this width.
  static const double insightsTablet = 600;

  /// Insights body unlocks the 3-column row under the chart at this
  /// width.
  static const double insightsDesktop = 900;

  /// Modal presentation switch: phone shows bottom sheets, tablet+
  /// shows centered dialogs.
  static const double modalDialog = 600;
}

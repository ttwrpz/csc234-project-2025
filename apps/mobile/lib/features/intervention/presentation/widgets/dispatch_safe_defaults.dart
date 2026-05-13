import '../../../disclaimer/domain/disclaimer_copy.dart';

/// Hard-coded fallback bodies for the three tier screens when they are
/// opened with `dispatch == null` (e.g., via deep link, or via a router
/// debug visit). The dispatcher always populates `dispatch.body` with the
/// curated quote + `DisclaimerCopy.notificationFooter`; these constants
/// reconstruct the same shape so the screens always render the canonical
/// CLAUDE.md "Pre-approved intervention phrasing" and the disclaimer
/// footer.
///
/// **Tier 3 invariant:** the Tier 3 default is byte-for-byte identical to
/// `QuoteLibraryImpl.tier3Pool[0]` so a screen opened without a real
/// dispatch still surfaces a phrase that has been read aloud by the team
/// (HB-008 §"Curated pool authoring") and contains the literal Hotline
/// 1323 marker. The dispatcher composes the body as
/// `"${quote.text}\n\n${notificationFooter}"`; we mirror that here.
///
/// These strings are NEVER substituted into the wire-level audit doc —
/// they exist only for the screen renderer's null-safety branch.
abstract class DispatchSafeDefaults {
  /// Tier 1 fallback body — pre-approved Tier 1 quote + disclaimer footer.
  static const String tier1 =
      'It looks like your garden has had some rainy days. '
      'Would you like a 2-minute breathing exercise?\n\n'
      '${DisclaimerCopy.notificationFooter}';

  /// Tier 2 fallback body — pre-approved Tier 2 quote + disclaimer footer.
  static const String tier2 =
      'Would you like to write about what has been on your mind?\n\n'
      '${DisclaimerCopy.notificationFooter}';

  /// Tier 3 fallback body — byte-for-byte equal to
  /// `QuoteLibraryImpl.tier3Pool[0]` + footer. The literal "1323" marker
  /// MUST survive any edit: the crisis screen's defense-in-depth test
  /// asserts the rendered body contains "1323".
  static const String tier3 =
      'We care about you. If it helps to talk, the Thai Mental Health '
      'Hotline is free at 1323, 24 hours.\n\n'
      '${DisclaimerCopy.notificationFooter}';
}

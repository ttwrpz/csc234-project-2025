/// Canonical bipolar / medical disclaimer copy. Locked phrasing —
/// any change requires team review (spec §4 + CLAUDE.md "Pre-approved
/// intervention phrasing"). Tests in
/// `disclaimer_copy_test.dart` assert each constant byte-for-byte.
abstract class DisclaimerCopy {
  /// Used by the onboarding slide, the Settings → About cluster, and
  /// the (S5) Insights screen ack dialog.
  static const String full =
      "MoodBloom is not a medical device. It cannot diagnose conditions "
      "like bipolar disorder, depression, or anxiety. The patterns and "
      "insights it shows are observational only. If you're concerned "
      "about your mental health, please consult a qualified professional.";

  /// Short footer text — used (in S5) on every Tier 1/2/3 intervention
  /// notification body. Authored here so the dispatcher import is a
  /// 1-line change in S5.
  static const String notificationFooter =
      'MoodBloom is not a medical device. Not a substitute for '
      'professional care.';

  /// Ack-dialog primary button label.
  static const String ackButton = 'I understand';
}

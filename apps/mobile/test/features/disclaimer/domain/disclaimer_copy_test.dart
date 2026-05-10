import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';

/// Locked-copy regression guard. Spec §4 + CLAUDE.md fix the wording
/// of the bipolar/medical disclaimer; these byte-for-byte assertions
/// catch any accidental rewording before it can reach the user.
void main() {
  group('DisclaimerCopy', () {
    test('full version matches spec §4 verbatim', () {
      expect(
        DisclaimerCopy.full,
        "MoodBloom is not a medical device. It cannot diagnose conditions "
        "like bipolar disorder, depression, or anxiety. The patterns and "
        "insights it shows are observational only. If you're concerned "
        "about your mental health, please consult a qualified professional.",
      );
    });

    test('notification footer (short version) matches spec §4 verbatim', () {
      expect(
        DisclaimerCopy.notificationFooter,
        'MoodBloom is not a medical device. Not a substitute for '
        'professional care.',
      );
    });

    test('ack-dialog button label matches spec §4 verbatim', () {
      expect(DisclaimerCopy.ackButton, 'I understand');
    });
  });
}

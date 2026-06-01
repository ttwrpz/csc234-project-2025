import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

void main() {
  group('Tier.escalate - folds per-algorithm tier hits to the highest', () {
    test('(null, null) → null (no algorithm fired)', () {
      expect(Tier.escalate(null, null), isNull);
    });

    test('(one, null) → one (left-only)', () {
      expect(Tier.escalate(Tier.one, null), Tier.one);
    });

    test('(one, two) → two (right wins on higher severity)', () {
      expect(Tier.escalate(Tier.one, Tier.two), Tier.two);
    });

    test('(two, three) → three (right wins on higher severity)', () {
      expect(Tier.escalate(Tier.two, Tier.three), Tier.three);
    });

    test('(three, one) → three (left wins on higher severity)', () {
      expect(Tier.escalate(Tier.three, Tier.one), Tier.three);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/intervention/domain/entities/ai_allowed_tier.dart';
import 'package:moodbloom/features/pattern_engine/domain/entities/tier.dart';

void main() {
  group('AiAllowedTier.fromTier — ADR-0012 §"Decision" point 2', () {
    test('Tier.one → AiAllowedTier.one', () {
      expect(AiAllowedTier.fromTier(Tier.one), AiAllowedTier.one);
    });

    test('Tier.two → AiAllowedTier.two', () {
      expect(AiAllowedTier.fromTier(Tier.two), AiAllowedTier.two);
    });

    test('Tier.three throws StateError — compiler-level fence', () {
      // The dispatcher's `if (tier == Tier.three)` arm returns BEFORE
      // reaching this call, so the StateError path is unreachable in
      // production. The throw exists so a future refactor that deletes
      // the if-branch trips this test before reaching prod.
      expect(
        () => AiAllowedTier.fromTier(Tier.three),
        throwsA(isA<StateError>()),
      );
    });
  });
}

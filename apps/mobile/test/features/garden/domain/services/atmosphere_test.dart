import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';
import 'package:moodbloom/features/garden/domain/services/atmosphere.dart';

void main() {
  group('computeAtmosphere - service-level boundaries', () {
    test('empty list → calmSunny (morning-default neutral)', () {
      // No entries yet today; we render a calm sky rather than rain.
      expect(computeAtmosphere(const []), Atmosphere.calmSunny);
    });

    test('TC-16: one positive (+0.8) + one negative (-0.4) → avg +0.2 → '
        'calmSunny', () {
      // (0.8 + -0.4) / 2 = +0.2 → positive sign, magnitude < 0.3.
      expect(computeAtmosphere(const [0.8, -0.4]), Atmosphere.calmSunny);
    });

    test('avg exactly 0 → calmSunny (zero is non-negative)', () {
      expect(computeAtmosphere(const [0.4, -0.4]), Atmosphere.calmSunny);
    });

    test('avg exactly +0.3 → brightSunny (boundary)', () {
      expect(computeAtmosphere(const [0.3]), Atmosphere.brightSunny);
    });

    test('avg exactly -0.3 → storm (boundary)', () {
      expect(computeAtmosphere(const [-0.3]), Atmosphere.storm);
    });

    test('two strongly negative entries → storm', () {
      // (-0.8 + -0.6) / 2 = -0.7 → storm.
      expect(computeAtmosphere(const [-0.8, -0.6]), Atmosphere.storm);
    });
  });
}

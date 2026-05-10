import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/domain/entities/atmosphere.dart';

void main() {
  group('Atmosphere.fromAverage — boundary cuts (ADR-0010 §5)', () {
    test('avg = 0 → calmSunny (zero is non-negative)', () {
      expect(Atmosphere.fromAverage(0), Atmosphere.calmSunny);
    });

    test('avg = 0.0001 → calmSunny (just above zero, low magnitude)', () {
      expect(Atmosphere.fromAverage(0.0001), Atmosphere.calmSunny);
    });

    test('avg = 0.299 → calmSunny (just below 0.3 magnitude)', () {
      expect(Atmosphere.fromAverage(0.299), Atmosphere.calmSunny);
    });

    test(
      'avg = 0.3 → brightSunny (lower bound for high-magnitude positive)',
      () {
        expect(Atmosphere.fromAverage(0.3), Atmosphere.brightSunny);
      },
    );

    test('avg = 1.0 → brightSunny (top of the positive range)', () {
      expect(Atmosphere.fromAverage(1.0), Atmosphere.brightSunny);
    });

    test('avg = -0.0001 → lightRain (just below zero, low magnitude)', () {
      expect(Atmosphere.fromAverage(-0.0001), Atmosphere.lightRain);
    });

    test(
      'avg = -0.299 → lightRain (just above 0.3 magnitude on the negative side)',
      () {
        expect(Atmosphere.fromAverage(-0.299), Atmosphere.lightRain);
      },
    );

    test('avg = -0.3 → storm (lower bound for high-magnitude negative)', () {
      expect(Atmosphere.fromAverage(-0.3), Atmosphere.storm);
    });

    test('avg = -1.0 → storm (bottom of the negative range)', () {
      expect(Atmosphere.fromAverage(-1.0), Atmosphere.storm);
    });
  });
}

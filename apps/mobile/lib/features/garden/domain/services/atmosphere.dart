import '../entities/atmosphere.dart';

/// Computes the average of [todayScores] (per-entry `MoodScore.value` for
/// today) and maps it to an [Atmosphere] state. Returns
/// `Atmosphere.calmSunny` when `todayScores` is empty (the "morning, no
/// entries yet" neutral default — the user has not signalled anything,
/// so we render a calm sky rather than rain).
///
/// Pure Dart — domain layer.
Atmosphere computeAtmosphere(List<double> todayScores) {
  if (todayScores.isEmpty) return Atmosphere.calmSunny;
  var sum = 0.0;
  for (final s in todayScores) {
    sum += s;
  }
  final avg = sum / todayScores.length;
  return Atmosphere.fromAverage(avg);
}

/// 4-state daily atmosphere overlay derived from `avg_S_today`. Resets
/// at local midnight. Decoupled from `PlantTier`: the slow weekly EWMA
/// answers "how is the week trending?", the fast daily atmosphere
/// answers "how is today going so far?". See ADR-0010 §5.
///
/// Mapping (sign × magnitude):
///   * calmSunny    : avg_S >= 0   AND  |avg_S| < 0.3
///   * brightSunny  : avg_S >= 0   AND  |avg_S| >= 0.3
///   * lightRain    : avg_S < 0    AND  |avg_S| < 0.3
///   * storm        : avg_S < 0    AND  |avg_S| >= 0.3
///
/// Pure Dart — domain layer must not import Flutter/Firebase. Presentation
/// widgets (`AtmosphereOverlay`) translate these enum values into visuals.
enum Atmosphere {
  calmSunny,
  brightSunny,
  lightRain,
  storm;

  /// Maps the day's mean mood-score (`avg_S`, range [-1, +1]) to one of
  /// the 4 atmosphere states. The "morning, no entries yet" default is
  /// `calmSunny` — see `computeAtmosphere` for the empty-list contract.
  static Atmosphere fromAverage(double avgS) {
    final magnitude = avgS.abs();
    if (avgS >= 0) {
      return magnitude >= 0.3 ? Atmosphere.brightSunny : Atmosphere.calmSunny;
    }
    return magnitude >= 0.3 ? Atmosphere.storm : Atmosphere.lightRain;
  }
}

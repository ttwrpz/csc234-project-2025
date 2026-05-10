/// 5-tier ecosystem state mapped from `H_t` (Garden Health EWMA). Every
/// tier renders plants alive — the Storm Season tier shows rain falling
/// AROUND the garden with plants sheltered (never wilting, never dying).
/// See ADR-0010 §4 for thresholds and visual language.
///
/// Threshold cuts. Each boundary belongs to the more-extreme tier (the
/// one further from zero) so `fromHealth(0.4)` is flourishing and
/// `fromHealth(-0.4)` is stormSeason — symmetric on both sides of zero:
///   * Flourishing    : H >=  +0.4
///   * Thriving       : +0.1 <= H <  +0.4
///   * Resting        : -0.1 <  H <  +0.1
///   * Weathering     : -0.4 <  H <= -0.1
///   * Storm Season   :          H <= -0.4
///
/// Pure Dart — domain layer must not import Flutter/Firebase. Presentation
/// widgets (`PlantTierGroup`) translate these enum values into visuals.
enum PlantTier {
  flourishing,
  thriving,
  resting,
  weathering,
  stormSeason;

  /// Maps a continuous Garden Health value (`H_t`, range [-1, +1]) to one
  /// of the 5 ecosystem tiers per the cuts above.
  static PlantTier fromHealth(double h) {
    if (h >= 0.4) return PlantTier.flourishing;
    if (h >= 0.1) return PlantTier.thriving;
    if (h <= -0.4) return PlantTier.stormSeason;
    if (h <= -0.1) return PlantTier.weathering;
    return PlantTier.resting;
  }
}

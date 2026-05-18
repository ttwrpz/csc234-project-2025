import '../../../garden/domain/entities/flower_species.dart';
import '../entities/flower_skin.dart';

/// In-memory catalog of every flower-skin variant the app ships with —
/// the read-only source of truth the modal renders from.
///
/// Each species has exactly one default skin (`isDefault: true`,
/// `cost: 0`) plus a small set of alternates priced in tokens. Defaults
/// are NEVER stored in `unlockedSkins` (always available without
/// purchase); alternates are gated by the unlock flow.
///
/// Pure Dart on purpose. The catalog is hand-authored rather than
/// loaded from Firestore because:
///   1. Cosmetic content is small and immutable.
///   2. A hot-reloadable client-side catalog removes a network round-
///      trip from the modal's open path.
///   3. Pricing changes ship via app update (same blast radius as a
///      copy change), so there's no need for a remote-config indirection.
///
/// `paletteSeed` is an integer the painter uses to derive the skin's
/// colour ramp deterministically — it doesn't carry any business
/// meaning, just makes alternate skins look distinct on the modal grid
/// without requiring a `Color` import in the domain layer.
///
/// Invariants enforced by construction:
///   * Costs are uniform per tier (50 / 100 / 150 tokens) — never
///     mood-contingent. The pricing surface has no parameter for mood
///     or intensity.
///   * No skin's `displayName` references a mood or emotion ("Cheerful
///     Sunflower" would be a violation — it implies mood-content
///     gating). Names are visual descriptors only.
class SkinCatalog {
  const SkinCatalog._();

  /// Default cost for the entry-level alternate skin per species.
  static const int _tierBronze = 50;

  /// Mid-tier alternate skin cost.
  static const int _tierSilver = 100;

  /// Top-tier alternate skin cost.
  static const int _tierGold = 150;

  /// Premium tier for geometry-changing skins (heart, star petals).
  /// Higher cost reflects the larger visual difference vs a plain
  /// palette swap.
  static const int _tierPlatinum = 200;
  static const int _tierMythic = 250;

  /// Every skin in the app, grouped by species. Stable order — the
  /// default always comes first.
  static List<FlowerSkin> all() => const [
    // Sunflower (Happy)
    FlowerSkin(
      skinId: 'sunflower_default',
      species: FlowerSpecies.sunflower,
      displayName: 'Classic Sunflower',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'sunflower_sunset',
      species: FlowerSpecies.sunflower,
      displayName: 'Sunset Sunflower',
      cost: _tierBronze,
      isDefault: false,
      paletteSeed: 12,
    ),
    FlowerSkin(
      skinId: 'sunflower_moonlit',
      species: FlowerSpecies.sunflower,
      displayName: 'Moonlit Sunflower',
      cost: _tierSilver,
      isDefault: false,
      paletteSeed: 27,
    ),
    FlowerSkin(
      skinId: 'sunflower_starburst',
      species: FlowerSpecies.sunflower,
      displayName: 'Starburst Sunflower',
      cost: _tierGold,
      isDefault: false,
      paletteSeed: 33,
      petalShape: FlowerPetalShape.star,
    ),

    // Forget-me-not (Sad)
    FlowerSkin(
      skinId: 'forgetmenot_default',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Classic Forget-me-not',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'forgetmenot_lilac',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Lilac Forget-me-not',
      cost: _tierBronze,
      isDefault: false,
      paletteSeed: 14,
    ),
    FlowerSkin(
      skinId: 'forgetmenot_pointed_sky',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Pointed Sky Forget-me-not',
      cost: _tierGold,
      isDefault: false,
      paletteSeed: 19,
      petalShape: FlowerPetalShape.pointed,
    ),

    // Daisy (Okay)
    FlowerSkin(
      skinId: 'daisy_default',
      species: FlowerSpecies.daisy,
      displayName: 'Classic Daisy',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'daisy_blushing',
      species: FlowerSpecies.daisy,
      displayName: 'Blushing Daisy',
      cost: _tierBronze,
      isDefault: false,
      paletteSeed: 18,
    ),
    FlowerSkin(
      skinId: 'daisy_heartleaf',
      species: FlowerSpecies.daisy,
      displayName: 'Heartleaf Daisy',
      cost: _tierPlatinum,
      isDefault: false,
      paletteSeed: 25,
      petalShape: FlowerPetalShape.heart,
    ),

    // Poppy (Angry)
    FlowerSkin(
      skinId: 'poppy_default',
      species: FlowerSpecies.poppy,
      displayName: 'Classic Poppy',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'poppy_amber',
      species: FlowerSpecies.poppy,
      displayName: 'Amber Poppy',
      cost: _tierSilver,
      isDefault: false,
      paletteSeed: 22,
    ),
    FlowerSkin(
      skinId: 'poppy_rounded_ember',
      species: FlowerSpecies.poppy,
      displayName: 'Rounded Ember Poppy',
      cost: _tierPlatinum,
      isDefault: false,
      paletteSeed: 29,
      petalShape: FlowerPetalShape.rounded,
    ),

    // Fern (Anxious)
    FlowerSkin(
      skinId: 'fern_default',
      species: FlowerSpecies.fern,
      displayName: 'Classic Fern',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'fern_forest',
      species: FlowerSpecies.fern,
      displayName: 'Forest Fern',
      cost: _tierBronze,
      isDefault: false,
      paletteSeed: 9,
    ),

    // Lavender (Calm)
    FlowerSkin(
      skinId: 'lavender_default',
      species: FlowerSpecies.lavender,
      displayName: 'Classic Lavender',
      cost: 0,
      isDefault: true,
      paletteSeed: 0,
    ),
    FlowerSkin(
      skinId: 'lavender_twilight',
      species: FlowerSpecies.lavender,
      displayName: 'Twilight Lavender',
      cost: _tierSilver,
      isDefault: false,
      paletteSeed: 31,
    ),
    FlowerSkin(
      skinId: 'lavender_meadow',
      species: FlowerSpecies.lavender,
      displayName: 'Meadow Lavender',
      cost: _tierGold,
      isDefault: false,
      paletteSeed: 44,
    ),
    FlowerSkin(
      skinId: 'lavender_star_twilight',
      species: FlowerSpecies.lavender,
      displayName: 'Star Twilight Lavender',
      cost: _tierMythic,
      isDefault: false,
      paletteSeed: 51,
      petalShape: FlowerPetalShape.star,
    ),
  ];

  /// Skins for [species] in display order (default first, then
  /// alternates by ascending cost). Stable across rebuilds.
  static List<FlowerSkin> forSpecies(FlowerSpecies species) =>
      all().where((s) => s.species == species).toList(growable: false);

  /// Looks up a skin by [skinId]. Returns `null` for unknown ids — the
  /// caller decides whether to fall back to the species default or
  /// surface an error.
  static FlowerSkin? byId(String skinId) {
    for (final s in all()) {
      if (s.skinId == skinId) return s;
    }
    return null;
  }

  /// Returns the default skin for [species]. Guaranteed to exist for
  /// every species; throws [StateError] if a future refactor accidentally
  /// removes one (defensive — the test suite catches this too).
  static FlowerSkin defaultFor(FlowerSpecies species) {
    for (final s in all()) {
      if (s.species == species && s.isDefault) return s;
    }
    throw StateError('No default skin registered for species $species');
  }
}

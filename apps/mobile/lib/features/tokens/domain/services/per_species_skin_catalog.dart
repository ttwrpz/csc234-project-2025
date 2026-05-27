import '../../../garden/domain/entities/flower_species.dart';
import '../entities/per_species_skin.dart';

/// In-memory catalog of the per-species flower skins - two tasteful
/// alternate accents for each of the six [FlowerSpecies] (12 total).
///
/// This catalog is ADDITIVE to [GardenSkinCatalog] (the five global
/// skins); the two systems coexist by product decision. A per-species
/// skin recolours only its own species' bloom, layered over whatever
/// global skin is equipped.
///
/// Pure Dart, hand-authored. Pricing is consistent with the global
/// catalog (which spans 12..40 tokens): per-species accents are the
/// cheaper, more granular tier at 8..14 tokens, so a user can personalise
/// a single favourite flower for less than a whole-garden reskin.
///
/// Invariants (covered by `per_species_skin_catalog_test.dart`):
///   * Every species has exactly two alternates.
///   * Every id is unique and prefixed with its species name.
///   * Costs are positive (no free per-species defaults - the built-in
///     species colour IS the free default).
///   * Tagline copy follows CLAUDE.md: hyphens not em-dashes, no clinical
///     or mood-contingent phrasing.
class PerSpeciesSkinCatalog {
  const PerSpeciesSkinCatalog._();

  /// Every per-species skin in display order, grouped by species.
  static const List<PerSpeciesSkin> all = <PerSpeciesSkin>[
    // Sunflower (Joy).
    PerSpeciesSkin(
      id: 'sunflower_goldenHour',
      species: FlowerSpecies.sunflower,
      displayName: 'Golden Hour',
      tagline: 'A warmer amber, like late-afternoon light.',
      cost: 10,
      accentArgb: 0xFFF2A93B,
    ),
    PerSpeciesSkin(
      id: 'sunflower_butter',
      species: FlowerSpecies.sunflower,
      displayName: 'Butter Bloom',
      tagline: 'Soft pale yellow with a gentle glow.',
      cost: 8,
      accentArgb: 0xFFF7D779,
    ),
    // Lavender (Calm).
    PerSpeciesSkin(
      id: 'lavender_twilight',
      species: FlowerSpecies.lavender,
      displayName: 'Twilight Sprig',
      tagline: 'A deeper violet for quiet evenings.',
      cost: 10,
      accentArgb: 0xFF8A6FB8,
    ),
    PerSpeciesSkin(
      id: 'lavender_dawnMist',
      species: FlowerSpecies.lavender,
      displayName: 'Dawn Mist',
      tagline: 'Pale lilac, soft as morning haze.',
      cost: 8,
      accentArgb: 0xFFC3B6E0,
    ),
    // Daisy (Okay).
    PerSpeciesSkin(
      id: 'daisy_blush',
      species: FlowerSpecies.daisy,
      displayName: 'Blush Daisy',
      tagline: 'A friendly rose tint on the petals.',
      cost: 9,
      accentArgb: 0xFFE9A6B0,
    ),
    PerSpeciesSkin(
      id: 'daisy_skyline',
      species: FlowerSpecies.daisy,
      displayName: 'Skyline',
      tagline: 'Cool periwinkle, calm and clear.',
      cost: 9,
      accentArgb: 0xFFA9C2E3,
    ),
    // Poppy (Anger).
    PerSpeciesSkin(
      id: 'poppy_emberRose',
      species: FlowerSpecies.poppy,
      displayName: 'Ember Rose',
      tagline: 'A softer coral-red, less fierce, still bold.',
      cost: 12,
      accentArgb: 0xFFE0716A,
    ),
    PerSpeciesSkin(
      id: 'poppy_plum',
      species: FlowerSpecies.poppy,
      displayName: 'Plum Poppy',
      tagline: 'A rich plum that settles the heat.',
      cost: 12,
      accentArgb: 0xFF9C5A7A,
    ),
    // Fern (Anxiety).
    PerSpeciesSkin(
      id: 'fern_seafoam',
      species: FlowerSpecies.fern,
      displayName: 'Seafoam Frond',
      tagline: 'A breezy blue-green, light on the eye.',
      cost: 10,
      accentArgb: 0xFF6FBFA6,
    ),
    PerSpeciesSkin(
      id: 'fern_mossGold',
      species: FlowerSpecies.fern,
      displayName: 'Moss & Gold',
      tagline: 'Warm olive with a sunlit edge.',
      cost: 10,
      accentArgb: 0xFF8FA85C,
    ),
    // Forget-me-not (Sad).
    PerSpeciesSkin(
      id: 'forgetMeNot_periwinkle',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Periwinkle',
      tagline: 'A brighter blue, like clearing skies.',
      cost: 9,
      accentArgb: 0xFF8BA6E0,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_seaGlass',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Sea Glass',
      tagline: 'A gentle teal, washed smooth and soft.',
      cost: 9,
      accentArgb: 0xFF7FBDC0,
    ),
  ];

  /// Looks up a skin by [id]. Returns `null` when the id is unknown
  /// (e.g. a Firestore doc carries a slug from a future catalog version).
  /// Callers treat `null` as "fall back to the global / default skin".
  static PerSpeciesSkin? byId(String id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return null;
  }

  /// All skins for a single [species], in display order.
  static List<PerSpeciesSkin> forSpecies(FlowerSpecies species) =>
      all.where((s) => s.species == species).toList(growable: false);
}

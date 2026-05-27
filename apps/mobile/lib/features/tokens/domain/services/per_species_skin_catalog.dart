import 'package:design_system/design_system.dart' show GardenSkinId;

import '../../../garden/domain/entities/flower_species.dart';
import '../entities/per_species_skin.dart';

/// In-memory catalog of the per-species flower skins - SIX variants for
/// each of the six [FlowerSpecies] (36 total).
///
/// This catalog is ADDITIVE to [GardenSkinCatalog] (the five global
/// skins); the two systems coexist by product decision. A per-species
/// skin overrides only its own species' plant - both its SHAPE (one of
/// the five `MbSkinPlant` style languages) and its accent colour -
/// layered over whatever global skin is equipped.
///
/// Per species the six variants are:
///   1. the CLASSIC meadow silhouette (the "first", kept stable),
///   2-5. four genuinely distinct shapes - origami / lantern /
///        constellation / crystal,
///   6. a second classic colour.
///
/// Pure Dart, hand-authored. Pricing stays in the cheaper 8..12 band
/// (the cheapest global skin is 12) so personalising one flower always
/// costs less than a whole-garden reskin.
///
/// Invariants (covered by `per_species_skin_catalog_test.dart`):
///   * Every species has exactly six variants.
///   * Every id is unique and prefixed with its species name.
///   * Costs are positive and <= 12.
///   * Variant 1 per species uses `GardenSkinId.meadow` (the classic).
///   * Tagline copy follows CLAUDE.md: hyphens not em-dashes, no clinical
///     or mood-contingent phrasing.
class PerSpeciesSkinCatalog {
  const PerSpeciesSkinCatalog._();

  /// Every per-species skin in display order, grouped by species.
  static const List<PerSpeciesSkin> all = <PerSpeciesSkin>[
    // ---- Sunflower (Joy) ----
    PerSpeciesSkin(
      id: 'sunflower_goldenHour',
      species: FlowerSpecies.sunflower,
      displayName: 'Golden Hour',
      tagline: 'The classic bloom in warm late-afternoon amber.',
      cost: 10,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFF2A93B,
    ),
    PerSpeciesSkin(
      id: 'sunflower_origami',
      species: FlowerSpecies.sunflower,
      displayName: 'Folded Sun',
      tagline: 'A crane-fold sunflower in bright paper yellow.',
      cost: 9,
      style: GardenSkinId.origami,
      accentArgb: 0xFFF7C948,
    ),
    PerSpeciesSkin(
      id: 'sunflower_lantern',
      species: FlowerSpecies.sunflower,
      displayName: 'Lantern Sun',
      tagline: 'A glowing paper lantern, warm as dusk.',
      cost: 10,
      style: GardenSkinId.lantern,
      accentArgb: 0xFFF6A23B,
    ),
    PerSpeciesSkin(
      id: 'sunflower_constellation',
      species: FlowerSpecies.sunflower,
      displayName: 'Sunlit Stars',
      tagline: 'A little constellation in soft gold.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFFFFD66B,
    ),
    PerSpeciesSkin(
      id: 'sunflower_crystal',
      species: FlowerSpecies.sunflower,
      displayName: 'Amber Gem',
      tagline: 'A faceted amber crystal that catches the light.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFFE8A23B,
    ),
    PerSpeciesSkin(
      id: 'sunflower_butter',
      species: FlowerSpecies.sunflower,
      displayName: 'Butter Bloom',
      tagline: 'The classic bloom in soft pale yellow.',
      cost: 8,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFF7D779,
    ),
    // ---- Lavender (Calm) ----
    PerSpeciesSkin(
      id: 'lavender_twilight',
      species: FlowerSpecies.lavender,
      displayName: 'Twilight Sprig',
      tagline: 'The classic spike in a deeper evening violet.',
      cost: 10,
      style: GardenSkinId.meadow,
      accentArgb: 0xFF8A6FB8,
    ),
    PerSpeciesSkin(
      id: 'lavender_origami',
      species: FlowerSpecies.lavender,
      displayName: 'Folded Dusk',
      tagline: 'A folded-paper sprig in muted violet.',
      cost: 9,
      style: GardenSkinId.origami,
      accentArgb: 0xFF9B82C9,
    ),
    PerSpeciesSkin(
      id: 'lavender_lantern',
      species: FlowerSpecies.lavender,
      displayName: 'Lantern Dusk',
      tagline: 'A slim paper lantern in quiet purple.',
      cost: 10,
      style: GardenSkinId.lantern,
      accentArgb: 0xFF7E6BA8,
    ),
    PerSpeciesSkin(
      id: 'lavender_constellation',
      species: FlowerSpecies.lavender,
      displayName: 'Violet Stars',
      tagline: 'A vertical line of soft violet stars.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFFB9A7E6,
    ),
    PerSpeciesSkin(
      id: 'lavender_crystal',
      species: FlowerSpecies.lavender,
      displayName: 'Amethyst',
      tagline: 'A slim amethyst crystal, cool and clear.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFF7C5FB0,
    ),
    PerSpeciesSkin(
      id: 'lavender_dawnMist',
      species: FlowerSpecies.lavender,
      displayName: 'Dawn Mist',
      tagline: 'The classic spike in pale morning lilac.',
      cost: 8,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFC3B6E0,
    ),
    // ---- Daisy (Okay) ----
    PerSpeciesSkin(
      id: 'daisy_blush',
      species: FlowerSpecies.daisy,
      displayName: 'Blush Daisy',
      tagline: 'The classic daisy with a friendly rose tint.',
      cost: 9,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFE9A6B0,
    ),
    PerSpeciesSkin(
      id: 'daisy_origami',
      species: FlowerSpecies.daisy,
      displayName: 'Folded Petal',
      tagline: 'A folded-paper daisy in soft pink.',
      cost: 9,
      style: GardenSkinId.origami,
      accentArgb: 0xFFEFB6C0,
    ),
    PerSpeciesSkin(
      id: 'daisy_lantern',
      species: FlowerSpecies.daisy,
      displayName: 'Lantern Bloom',
      tagline: 'A small hexagonal lantern in dusty rose.',
      cost: 10,
      style: GardenSkinId.lantern,
      accentArgb: 0xFFDDA0AC,
    ),
    PerSpeciesSkin(
      id: 'daisy_constellation',
      species: FlowerSpecies.daisy,
      displayName: 'Petal Stars',
      tagline: 'A triangle of pale-pink stars.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFFF2C2CC,
    ),
    PerSpeciesSkin(
      id: 'daisy_crystal',
      species: FlowerSpecies.daisy,
      displayName: 'Rose Quartz',
      tagline: 'A gentle rose-quartz gem.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFFE08A98,
    ),
    PerSpeciesSkin(
      id: 'daisy_skyline',
      species: FlowerSpecies.daisy,
      displayName: 'Skyline',
      tagline: 'The classic daisy in cool periwinkle.',
      cost: 9,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFA9C2E3,
    ),
    // ---- Poppy (Anger) ----
    PerSpeciesSkin(
      id: 'poppy_emberRose',
      species: FlowerSpecies.poppy,
      displayName: 'Ember Rose',
      tagline: 'The classic poppy in a softer coral-red.',
      cost: 12,
      style: GardenSkinId.meadow,
      accentArgb: 0xFFE0716A,
    ),
    PerSpeciesSkin(
      id: 'poppy_origami',
      species: FlowerSpecies.poppy,
      displayName: 'Folded Flame',
      tagline: 'A folded-paper burst in warm coral.',
      cost: 10,
      style: GardenSkinId.origami,
      accentArgb: 0xFFE8857E,
    ),
    PerSpeciesSkin(
      id: 'poppy_lantern',
      species: FlowerSpecies.poppy,
      displayName: 'Lantern Flame',
      tagline: 'A spiky paper lantern in deep coral.',
      cost: 11,
      style: GardenSkinId.lantern,
      accentArgb: 0xFFD9645C,
    ),
    PerSpeciesSkin(
      id: 'poppy_constellation',
      species: FlowerSpecies.poppy,
      displayName: 'Ember Stars',
      tagline: 'A jagged line of warm-coral stars.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFFF09A94,
    ),
    PerSpeciesSkin(
      id: 'poppy_crystal',
      species: FlowerSpecies.poppy,
      displayName: 'Garnet',
      tagline: 'A deep garnet gem with a quiet glow.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFFC8423A,
    ),
    PerSpeciesSkin(
      id: 'poppy_plum',
      species: FlowerSpecies.poppy,
      displayName: 'Plum Poppy',
      tagline: 'The classic poppy in a rich settled plum.',
      cost: 12,
      style: GardenSkinId.meadow,
      accentArgb: 0xFF9C5A7A,
    ),
    // ---- Fern (Anxiety) ----
    PerSpeciesSkin(
      id: 'fern_seafoam',
      species: FlowerSpecies.fern,
      displayName: 'Seafoam Frond',
      tagline: 'The classic fern in a breezy blue-green.',
      cost: 10,
      style: GardenSkinId.meadow,
      accentArgb: 0xFF6FBFA6,
    ),
    PerSpeciesSkin(
      id: 'fern_origami',
      species: FlowerSpecies.fern,
      displayName: 'Folded Frond',
      tagline: 'A folded-paper frond in fresh green.',
      cost: 9,
      style: GardenSkinId.origami,
      accentArgb: 0xFF7FC9B0,
    ),
    PerSpeciesSkin(
      id: 'fern_lantern',
      species: FlowerSpecies.fern,
      displayName: 'Lantern Fern',
      tagline: 'A bamboo-segment lantern in soft green.',
      cost: 10,
      style: GardenSkinId.lantern,
      accentArgb: 0xFF5FA890,
    ),
    PerSpeciesSkin(
      id: 'fern_constellation',
      species: FlowerSpecies.fern,
      displayName: 'Frond Stars',
      tagline: 'An ear-of-stars in pale jade.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFF9AD9C2,
    ),
    PerSpeciesSkin(
      id: 'fern_crystal',
      species: FlowerSpecies.fern,
      displayName: 'Jade',
      tagline: 'Stacked jade crystals, calm and cool.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFF4F9E84,
    ),
    PerSpeciesSkin(
      id: 'fern_mossGold',
      species: FlowerSpecies.fern,
      displayName: 'Moss & Gold',
      tagline: 'The classic fern in warm sunlit olive.',
      cost: 10,
      style: GardenSkinId.meadow,
      accentArgb: 0xFF8FA85C,
    ),
    // ---- Forget-me-not (Sad) ----
    PerSpeciesSkin(
      id: 'forgetMeNot_periwinkle',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Periwinkle',
      tagline: 'The classic flower in a brighter clearing blue.',
      cost: 9,
      style: GardenSkinId.meadow,
      accentArgb: 0xFF8BA6E0,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_origami',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Folded Sky',
      tagline: 'A folded-paper bloom in soft sky blue.',
      cost: 9,
      style: GardenSkinId.origami,
      accentArgb: 0xFF9CB4E6,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_lantern',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Lantern Blue',
      tagline: 'A drooping paper lantern in gentle blue.',
      cost: 10,
      style: GardenSkinId.lantern,
      accentArgb: 0xFF7C97D2,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_constellation',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Sky Stars',
      tagline: 'A falling line of pale-blue stars.',
      cost: 11,
      style: GardenSkinId.constellation,
      accentArgb: 0xFFB3C6EE,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_crystal',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Sapphire',
      tagline: 'A small sapphire gem, washed clear.',
      cost: 12,
      style: GardenSkinId.crystal,
      accentArgb: 0xFF6C8AD0,
    ),
    PerSpeciesSkin(
      id: 'forgetMeNot_seaGlass',
      species: FlowerSpecies.forgetMeNot,
      displayName: 'Sea Glass',
      tagline: 'The classic flower in a smooth gentle teal.',
      cost: 9,
      style: GardenSkinId.meadow,
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

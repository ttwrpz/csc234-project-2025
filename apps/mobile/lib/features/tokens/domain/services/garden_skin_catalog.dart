import 'package:design_system/design_system.dart' show GardenSkinId;

import '../entities/garden_skin.dart';

/// In-memory catalog of the five global garden skins. Replaces the
/// per-species `SkinCatalog` that shipped through Sprint 5 v1.5.
///
/// Pure Dart, hand-authored. Cosmetic content is small, immutable, and
/// hot-reloadable. Order matches the Skin Shop's display order:
/// meadow (default) -> origami -> lantern -> constellation -> crystal.
///
/// Invariants enforced by construction:
///   * Exactly one skin has `cost == 0` (Meadow, the default).
///   * Costs grow monotonically across the list.
///   * Tagline copy follows the CLAUDE.md rule: no em-dashes - they are
///     replaced with hyphens. No clinical or mood-contingent phrasing.
class GardenSkinCatalog {
  const GardenSkinCatalog._();

  /// Every skin in display order. `meadow` is always first.
  static const List<GardenSkin> all = <GardenSkin>[
    GardenSkin(
      id: GardenSkinId.meadow,
      displayName: 'Meadow',
      tagline: 'The original - soft, living, and ready to grow with you.',
      cost: 0,
    ),
    GardenSkin(
      id: GardenSkinId.origami,
      displayName: 'Origami',
      tagline: 'Folded paper geometry. Crisp angles, gentle palette.',
      cost: 12,
    ),
    GardenSkin(
      id: GardenSkinId.lantern,
      displayName: 'Lantern',
      tagline: 'Hanging paper lanterns at dusk. Warm glow, quiet light.',
      cost: 20,
    ),
    GardenSkin(
      id: GardenSkinId.constellation,
      displayName: 'Constellation',
      tagline: 'Star clusters connected by dashed stems.',
      cost: 30,
    ),
    GardenSkin(
      id: GardenSkinId.crystal,
      displayName: 'Crystal',
      tagline: 'Faceted gems. Reach Flourishing tier to unlock.',
      cost: 40,
      requiresFlourishingTier: true,
    ),
  ];

  /// Looks up a skin by [id]. Throws [StateError] if a refactor accidentally
  /// removes an entry - all five ids must always resolve.
  static GardenSkin byId(GardenSkinId id) => all.firstWhere((s) => s.id == id);

  /// The default skin (Meadow). Always free, always unlocked, always first.
  static GardenSkin get defaultSkin => all.first;
}

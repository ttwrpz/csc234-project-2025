/// Identifier for one of the five global garden skins.
///
/// A skin is a complete alternate visual style for ALL six mood plants
/// at once - not per-species. This is intentionally a small enum living
/// in the design_system package so the painter library
/// (`mb_skin_plants.dart`) can dispatch on it without depending on
/// `apps/mobile`'s feature folder. The feature folder's `GardenSkin`
/// entity references this same enum so the domain and the painter never
/// drift out of sync.
///
/// Order matches the prototype skin order: meadow (default / free),
/// origami, lantern, constellation, crystal (locked behind the
/// Flourishing tier).
enum GardenSkinId { meadow, origami, lantern, constellation, crystal }

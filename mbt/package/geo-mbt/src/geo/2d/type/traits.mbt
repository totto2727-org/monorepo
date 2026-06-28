// Constraint-only traits for the geometry primitive types.
//
// These traits aggregate the inherent per-type methods that already exist in
// the same package (e.g. `LineString::is_empty`, `MultiPoint::length`) into a
// reusable behavioural contract. The trait `impl` blocks live in each
// struct's own file so the contract sits next to the data definition.
//
// Algorithm-layer traits (`CoordsCarrier`, `Bounded`, `HasArea`,
// `HasCentroid`, `HasEuclideanLength`, `LinesCarrier`, `HasDimensions`,
// `HasConvexHull`, `HasExtremes`, `ExteriorCoordsCarrier`, `ClosestPoint`,
// `CoordPositionFor`, `Simplify`, `Densify`, `MapCoords`) live colocated
// with their impls in each algorithm-layer source file under `geo/2d/`
// (e.g. `area.mbt`, `bounding_rect.mbt`, `lines_iter.mbt`). The
// previously-monolithic `geo/2d/traits.mbt` was dismantled in commit
// `c8b61f2` so that the contract sits next to its canonical implementations.

///|
/// Anything that can be empty (zero coords / zero components). Mirrors the
/// `is_empty()` inherent method present on every collection-shaped type.
pub(open) trait IsEmpty {
  fn is_empty(Self) -> Bool
}

///|
/// Anything that can be a closed ring (first and last coord equal).
pub(open) trait IsClosed {
  fn is_closed(Self) -> Bool
}

///|
/// Collection-style cardinality (number of components or coords). Mirrors
/// `Vec::len()` / `Array::length()`. Distinct from `HasEuclideanLength` (the
/// physical length of a curve, defined in `geo/2d/traits.mbt`).
pub(open) trait HasLength {
  fn length(Self) -> Int
}

// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/kernels/mod.rs
// and https://github.com/georust/geo/blob/main/geo/src/algorithm/kernels/robust.rs

///|
/// Orientation of three coordinates `p`, `q`, `r` in the plane.
pub(all) enum Orientation {
  CounterClockwise
  Clockwise
  Collinear
} derive(Eq, Debug)

///|
/// Returns the `Orientation` of three coordinates using a robust predicate
/// (`@robust.orient2d`). This corresponds to `RobustKernel::orient2d` in the
/// Rust geo crate.
pub fn orient(p : @type.Coord, q : @type.Coord, r : @type.Coord) -> Orientation {
  let det = @robust.orient2d(p, q, r)
  if det > 0.0 {
    CounterClockwise
  } else if det < 0.0 {
    Clockwise
  } else {
    Collinear
  }
}

///|
/// Convenience wrapper returning the raw signed area as `Double`.
pub fn signed_area_of_triangle_robust(
  p : @type.Coord,
  q : @type.Coord,
  r : @type.Coord,
) -> Double {
  @robust.orient2d(p, q, r)
}

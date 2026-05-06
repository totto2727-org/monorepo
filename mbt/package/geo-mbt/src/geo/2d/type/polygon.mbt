// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/polygon.rs

///|
/// A bounded two-dimensional area.
///
/// A `Polygon`'s outer boundary (`exterior`) is represented by a `LineString`
/// that is automatically closed. It may contain zero or more `interiors`
/// representing holes (rings within the polygon).
///
/// # Validity
///
/// Per the OGC SFA, a valid `Polygon` requires:
/// 1. Each ring is closed (first coord == last coord).
/// 2. Rings have at least 4 coords (3 unique).
/// 3. Rings do not self-cross.
/// 4. The exterior contains all interior rings, and interiors do not overlap.
///
/// This module does not enforce validity; use the `validation` algorithm
/// (planned for ms-15) for explicit checks.
pub struct Polygon {
  exterior : LineString
  interiors : Array[LineString]
} derive(Eq, Debug)

///|
/// Creates a new `Polygon`.
///
/// The exterior and each interior ring are closed in place if not already
/// closed (matching the Rust geo-types semantics).
pub fn Polygon::Polygon(
  exterior : LineString,
  interiors : Array[LineString],
) -> Polygon {
  exterior.close()
  for interior in interiors {
    interior.close()
  }
  Polygon::{ exterior, interiors }
}

///|
/// Returns the exterior ring.
pub fn Polygon::exterior(self : Polygon) -> LineString {
  self.exterior
}

///|
/// Returns the array of interior rings (holes).
pub fn Polygon::interiors(self : Polygon) -> Array[LineString] {
  self.interiors
}

///|
/// Returns the number of interior rings.
pub fn Polygon::num_interiors(self : Polygon) -> Int {
  self.interiors.length()
}

///|
/// Returns a new `Polygon` whose `interiors` are the original interiors plus
/// `new_interior` appended at the end. The original `Polygon` is not modified
/// (immutable counterpart of Rust upstream `Polygon::interiors_push`, which
/// mutates `&mut self`).
///
/// `new_interior` itself is also left untouched — it is cloned before being
/// auto-closed by the canonical `Polygon` constructor, so a caller passing
/// in their own `LineString` reference does not see it mutated as a side
/// effect.
///
/// **Performance**: the destination interiors `Array` is sized to its final
/// length (`n + 1`) in a single `Array::makei` allocation; existing interiors
/// are not re-cloned (each `LineString` reference is copied, not its coords).
/// No `push` loop is involved.
pub fn Polygon::with_pushed_interior(
  self : Polygon,
  new_interior : LineString,
) -> Polygon {
  let n = self.interiors.length()
  // Clone the input's coords array so closing the resulting LineString does
  // not mutate the caller's value. The canonical Polygon constructor below
  // will close it idempotently.
  let cloned_new = LineString::LineString(new_interior.coords().copy())
  // Single allocation sized to the final length; no incremental growth.
  let next_interiors = Array::makei(n + 1, fn(i) {
    if i < n {
      self.interiors[i]
    } else {
      cloned_new
    }
  })
  Polygon(self.exterior, next_interiors)
}

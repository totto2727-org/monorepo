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
/// The exterior and each interior ring are closed (auto-closure matches the
/// Rust geo-types semantics). The closure is **immutable**: each input
/// `LineString` is replaced via `LineString::closed`, which returns either
/// `self` (if already closed) or a fresh closed copy. The caller's
/// references are never mutated as a side effect of constructing a
/// `Polygon`.
pub fn Polygon::Polygon(
  exterior : LineString,
  interiors : Array[LineString],
) -> Polygon {
  let closed_exterior = exterior.closed()
  let closed_interiors = interiors.map(LineString::closed)
  Polygon::{ exterior: closed_exterior, interiors: closed_interiors }
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
/// Returns the number of interior rings (holes).
pub fn Polygon::num_interiors(self : Polygon) -> Int {
  self.interiors.length()
}

///|
/// Returns the total number of rings: exterior (1) plus interiors. Mirrors
/// Rust upstream `Polygon::num_rings`.
pub fn Polygon::num_rings(self : Polygon) -> Int {
  self.interiors.length() + 1
}

///|
/// Returns whether this polygon has no coordinates at all — i.e. its
/// exterior ring is empty. (Interior rings without an exterior are
/// nonsensical and not produced by the canonical constructor.)
pub fn Polygon::is_empty(self : Polygon) -> Bool {
  self.exterior.is_empty()
}

///|
/// Returns a new `Polygon` whose `interiors` are the original interiors plus
/// `new_interior` appended at the end. The original `Polygon` is not modified
/// (immutable counterpart of Rust upstream `Polygon::interiors_push`, which
/// mutates `&mut self`).
///
/// `new_interior` itself is also left untouched — `LineString::closed` is
/// used to obtain a closed view without mutating the caller's value (and
/// returns `self` when already closed, so no allocation occurs in that
/// case).
///
/// **Performance**: the destination interiors `Array` is sized to its final
/// length (`n + 1`) in a single `Array::makei` allocation. The canonical
/// `Polygon` constructor then re-runs `LineString::closed` on every entry,
/// but since the existing interiors and `closed_new` are already closed,
/// every per-element call returns `self` without copying.
pub fn Polygon::with_pushed_interior(
  self : Polygon,
  new_interior : LineString,
) -> Polygon {
  let n = self.interiors.length()
  let closed_new = new_interior.closed()
  let next_interiors = Array::makei(n + 1, fn(i) {
    if i < n {
      self.interiors[i]
    } else {
      closed_new
    }
  })
  Polygon(self.exterior, next_interiors)
}

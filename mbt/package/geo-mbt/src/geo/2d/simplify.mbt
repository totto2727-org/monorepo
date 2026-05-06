// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/simplify.rs

///|
/// Recursive Ramer-Douglas-Peucker. Returns the *interior* retained indices
/// (excluding `start` and `end`); the caller bookends the result with the
/// segment endpoints. Pure: creates new arrays via spread literals; the
/// input `coords` is never mutated.
fn rdp_recurse(
  coords : Array[@type.Coord],
  start : Int,
  end : Int,
  epsilon : Double,
) -> Array[Int] {
  if end <= start + 1 {
    return []
  }
  let line = @type.Line::Line(coords[start], coords[end])
  let acc = (start + 1)
    .until(end)
    .fold(init=(0.0, start), fn(acc, i) {
      let d = euclidean_distance_coord_to_line(coords[i], line)
      if d > acc.0 {
        (d, i)
      } else {
        acc
      }
    })
  let (max_dist, max_index) = acc
  if max_dist > epsilon {
    let left = rdp_recurse(coords, start, max_index, epsilon)
    let right = rdp_recurse(coords, max_index, end, epsilon)
    [..left, max_index, ..right]
  } else {
    []
  }
}

///|
/// Simplifies a `LineString` using the Ramer-Douglas-Peucker algorithm.
/// Coordinates whose perpendicular distance to the working segment is less
/// than `epsilon` are removed.
fn simplify_line_string(
  ls : @type.LineString,
  epsilon : Double,
) -> @type.LineString {
  let coords = ls.coords()
  if coords.length() < 3 {
    return ls
  }
  let middle = rdp_recurse(coords, 0, coords.length() - 1, epsilon)
  let kept_indices = [0, ..middle, coords.length() - 1]
  @type.LineString::LineString(kept_indices.map(fn(idx) { coords[idx] }))
}

///|
/// Returns the indices of the coordinates retained when simplifying with the
/// RDP algorithm.
pub fn simplify_line_string_indices(
  ls : @type.LineString,
  epsilon : Double,
) -> Array[Int] {
  let coords = ls.coords()
  if coords.length() < 3 {
    return Array::makei(coords.length(), fn(i) { i })
  }
  let middle = rdp_recurse(coords, 0, coords.length() - 1, epsilon)
  [0, ..middle, coords.length() - 1]
}

///|
/// Simplifies a `Polygon` by simplifying each ring with RDP.
fn simplify_polygon(polygon : @type.Polygon, epsilon : Double) -> @type.Polygon {
  let exterior = simplify_line_string(polygon.exterior(), epsilon)
  let interiors = polygon
    .interiors()
    .map(fn(ls) { simplify_line_string(ls, epsilon) })
  @type.Polygon::Polygon(exterior, interiors)
}

// MARK: trait Simplify + impls ----------------------------------------------

///|
/// RDP simplification with `epsilon`. Returns a value of the same type with
/// near-collinear coords removed.
pub(open) trait Simplify {
  simplify(Self, Double) -> Self
}

///|
pub impl Simplify for @type.LineString with simplify(self, epsilon) {
  simplify_line_string(self, epsilon)
}

///|
pub impl Simplify for @type.Polygon with simplify(self, epsilon) {
  simplify_polygon(self, epsilon)
}

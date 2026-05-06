// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/convex_hull/

///|
/// Computes the 2D convex hull of an array of coordinates using Andrew's
/// monotone chain algorithm. Returns a closed `LineString` (CCW orientation).
/// For fewer than 3 unique points the returned LineString may be degenerate.

///|
/// Lexicographic compare of two coordinates by (x, y).
fn coord_cmp(a : @type.Coord, b : @type.Coord) -> Int {
  if a.x() < b.x() {
    -1
  } else if a.x() > b.x() {
    1
  } else if a.y() < b.y() {
    -1
  } else if a.y() > b.y() {
    1
  } else {
    0
  }
}

///|
/// One step of Andrew's monotone chain: appends `c` to the running `chain`,
/// first popping any trailing coordinates that would create a non-left turn.
/// Pure: returns a new array via spread literals; does not mutate `chain`.
fn monotone_chain_step(
  chain : Array[@type.Coord],
  c : @type.Coord,
) -> Array[@type.Coord] {
  let n = chain.length()
  if n >= 2 && @robust.orient2d(chain[n - 2], chain[n - 1], c) <= 0.0 {
    // Drop the last coord and recurse — the next-to-last may also need to go.
    let shorter = Array::makei(n - 1, fn(k) { chain[k] })
    monotone_chain_step(shorter, c)
  } else {
    [..chain, c]
  }
}

///|
fn convex_hull_of_coords(coords : Array[@type.Coord]) -> @type.LineString {
  if coords.length() == 0 {
    return @type.LineString::LineString([])
  }
  if coords.length() == 1 {
    return @type.LineString::LineString([coords[0], coords[0]])
  }
  // Sort coords lexicographically by (x, y) without mutating the input.
  let sorted = Array::makei(coords.length(), fn(i) { coords[i] })
  sorted.sort_by(coord_cmp)
  // Lower / upper hull via Andrew's monotone chain. Each chain is built by
  // folding `monotone_chain_step` over the sorted (resp. reverse-sorted)
  // coords; the resulting arrays share their `[start, ..., end]` form so
  // dropping the last coord of each (it duplicates the first of the other)
  // gives the final ring.
  let lower = sorted.iter().fold(init=[], monotone_chain_step)
  let upper = sorted.rev_iter().fold(init=[], monotone_chain_step)
  let lower_n = lower.length()
  let upper_n = upper.length()
  // Concatenate `lower[0..lower_n-1]` ++ `upper[0..upper_n-1]` ++ `[lower[0]]`
  // to close the ring.
  let combined_len = lower_n - 1 + (upper_n - 1)
  if combined_len <= 0 {
    return @type.LineString::LineString([])
  }
  let hull = Array::makei(combined_len + 1, fn(k) {
    if k < lower_n - 1 {
      lower[k]
    } else if k < combined_len {
      upper[k - (lower_n - 1)]
    } else {
      lower[0]
    }
  })
  @type.LineString::LineString(hull)
}

///|
/// Convex hull of a `MultiPoint`.
fn convex_hull_of_multi_point(mp : @type.MultiPoint) -> @type.Polygon {
  let coords = mp.points().map(fn(p) { p.coord() })
  @type.Polygon::Polygon(convex_hull_of_coords(coords), [])
}

///|
/// Convex hull of a `LineString`. Returns a `Polygon`.
fn convex_hull_of_line_string(ls : @type.LineString) -> @type.Polygon {
  @type.Polygon::Polygon(convex_hull_of_coords(ls.coords()), [])
}

///|
/// Convex hull of a `Polygon` (uses its exterior ring's coords).
fn convex_hull_of_polygon(p : @type.Polygon) -> @type.Polygon {
  @type.Polygon::Polygon(convex_hull_of_coords(p.exterior().coords()), [])
}

///|
/// Convex hull of any `Geometry`. The hull is always a `Polygon`.
fn convex_hull_of_geometry(g : @type.Geometry) -> @type.Polygon {
  let coords = coords_of_geometry(g)
  @type.Polygon::Polygon(convex_hull_of_coords(coords), [])
}

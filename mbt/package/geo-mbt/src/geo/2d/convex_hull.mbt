// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/convex_hull/

///|
/// Computes the 2D convex hull of an array of coordinates using Andrew's
/// monotone chain algorithm. Returns a closed `LineString` (CCW orientation).
/// For fewer than 3 unique points the returned LineString may be degenerate.
fn convex_hull_of_coords(coords : Array[@type.Coord]) -> @type.LineString {
  if coords.length() == 0 {
    return @type.LineString::new([])
  }
  if coords.length() == 1 {
    return @type.LineString::new([coords[0], coords[0]])
  }
  // Sort coords lexicographically by (x, y).
  let sorted = coords.copy()
  sorted.sort_by(fn(a, b) {
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
  })

  // Lower hull
  let lower : Array[@type.Coord] = []
  for c in sorted {
    while lower.length() >= 2 {
      let n = lower.length()
      let det = @robust.orient2d(lower[n - 2], lower[n - 1], c)
      if det <= 0.0 {
        let _ = lower.pop()
      } else {
        break
      }
    }
    lower.push(c)
  }

  // Upper hull
  let upper : Array[@type.Coord] = []
  for i = sorted.length() - 1; i >= 0; i = i - 1 {
    let c = sorted[i]
    while upper.length() >= 2 {
      let n = upper.length()
      let det = @robust.orient2d(upper[n - 2], upper[n - 1], c)
      if det <= 0.0 {
        let _ = upper.pop()
      } else {
        break
      }
    }
    upper.push(c)
  }

  // Concatenate, removing the last coord of each chain (it is the first of
  // the other chain).
  let hull : Array[@type.Coord] = []
  for i = 0; i < lower.length() - 1; i = i + 1 {
    hull.push(lower[i])
  }
  for i = 0; i < upper.length() - 1; i = i + 1 {
    hull.push(upper[i])
  }
  // Close the ring
  if hull.length() > 0 {
    hull.push(hull[0])
  }
  @type.LineString::new(hull)
}

///|
/// Convex hull of a `MultiPoint`.
pub fn convex_hull_of_multi_point(mp : @type.MultiPoint) -> @type.Polygon {
  let coords = mp.points().map(fn(p) { p.coord() })
  @type.Polygon::new(convex_hull_of_coords(coords), [])
}

///|
/// Convex hull of a `LineString`. Returns a `Polygon`.
pub fn convex_hull_of_line_string(ls : @type.LineString) -> @type.Polygon {
  @type.Polygon::new(convex_hull_of_coords(ls.coords()), [])
}

///|
/// Convex hull of a `Polygon` (uses its exterior ring's coords).
pub fn convex_hull_of_polygon(p : @type.Polygon) -> @type.Polygon {
  @type.Polygon::new(convex_hull_of_coords(p.exterior().coords()), [])
}

///|
/// Convex hull of any `Geometry`. The hull is always a `Polygon`.
pub fn convex_hull_of_geometry(g : @type.Geometry) -> @type.Polygon {
  let coords = coords_of_geometry(g)
  @type.Polygon::new(convex_hull_of_coords(coords), [])
}

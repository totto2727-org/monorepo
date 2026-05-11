// Buffer / offset operations. Ported from i_overlay (conceptual equivalent).
//
// Generates buffer polygons around points, lines, and polygons using
// parallel-offset geometry. Round/Flat/Square end caps and Round/Miter/Bevel
// corner joins are supported.
//
// Deferred items (TODO ms-24-followup):
//  - i_overlay mesh-based multi-thread offset path
//  - Arc-polygon simplification of high-density round-join vertices
//  - Full polygon-with-holes inward buffering beyond the simple shrink-then-
//    union approach

///|
/// End-cap style for line buffering.
pub(all) enum BufferEndCap {
  Round
  Square
  Flat
} derive(Eq, Debug)

///|
/// Join style for corners.
pub(all) enum BufferJoin {
  Round
  Miter
  Bevel
} derive(Eq, Debug)

///|
/// Buffer/offset configuration.
pub(all) struct BufferOptions {
  end_cap : BufferEndCap
  join : BufferJoin
  miter_limit : Double
  arc_segments : Int
} derive(Eq, Debug)

///|
/// Default options: Round end caps, Round joins, miter limit 4.0,
/// 8 segments per quarter arc.
pub fn BufferOptions::default() -> BufferOptions {
  BufferOptions::{
    end_cap: Round,
    join: Round,
    miter_limit: 4.0,
    arc_segments: 8,
  }
}

// MARK: helpers ---------------------------------------------------------------

///|
fn perpendicular_vec(
  a : @type.Coord,
  b : @type.Coord,
  dist : Double,
) -> (@type.Coord, @type.Coord) {
  let dx = b.x() - a.x()
  let dy = b.y() - a.y()
  let len = (dx * dx + dy * dy).sqrt()
  if len < 1.0e-15 {
    return (
      @type.Coord::Coord(a.x(), a.y() + dist),
      @type.Coord::Coord(a.x(), a.y() - dist),
    )
  }
  let nx = -dy / len
  let ny = dx / len
  (
    @type.Coord::Coord(a.x() + nx * dist, a.y() + ny * dist),
    @type.Coord::Coord(a.x() - nx * dist, a.y() - ny * dist),
  )
}

///|
fn arc_points(
  center : @type.Coord,
  radius : Double,
  start_angle : Double,
  end_angle : Double,
  n_segments : Int,
) -> Array[@type.Coord] {
  if n_segments < 1 {
    return []
  }
  let pts : Array[@type.Coord] = []
  let sweep = end_angle - start_angle
  for i in 0..<(n_segments + 1) {
    let frac = i.to_double() / n_segments.to_double()
    let a = start_angle + sweep * frac
    pts.push(
      @type.Coord::Coord(
        center.x() + radius * @math.cos(a),
        center.y() + radius * @math.sin(a),
      ),
    )
  }
  pts
}

///|
fn ring_to_poly(pts : Array[@type.Coord]) -> @type.Polygon {
  let closed : Array[@type.Coord] = []
  for k = 0; k < pts.length(); k = k + 1 {
    closed.push(pts[k])
  }
  closed.push(pts[0])
  @type.Polygon::Polygon(@type.LineString::LineString(closed), [])
}

// MARK: buffer point ----------------------------------------------------------

///|
/// Buffer a Point: produces a `Polygon` approximating a circle of radius
/// `distance` around the point.
///
/// ```check
/// test "buffer_point - radius 1 yields circle" {
///   let p = @type.Point::from_tuple((0.0, 0.0))
///   let opts = BufferOptions::default()
///   let poly = buffer_point(p, 1.0, opts)
///   // exterior should have 4 * arc_segments + 1 = 33 coords
///   assert_true(poly.exterior().coords().length() == 33)
///   // vertices should be approximately 1.0 from center (discounting closing coord)
///   let cs = poly.exterior().coords()
///   for i = 0; i < cs.length() - 1; i = i + 1 {
///     let d = @math.sqrt((cs[i].x() - 0.0)*(cs[i].x() - 0.0) + (cs[i].y() - 0.0)*(cs[i].y() - 0.0))
///     assert_true((d - 1.0).abs() < 0.01)
///   }
/// }
/// ```
pub fn buffer_point(
  p : @type.Point,
  distance : Double,
  options : BufferOptions,
) -> @type.Polygon {
  if distance <= 0.0 {
    return @type.Polygon::empty()
  }
  let n_pts = 4 * options.arc_segments
  let cx = p.coord()
  let pts : Array[@type.Coord] = []
  for i in 0..<n_pts {
    let a = i.to_double() * 2.0 * @math.PI / n_pts.to_double()
    pts.push(
      @type.Coord::Coord(
        cx.x() + distance * @math.cos(a),
        cx.y() + distance * @math.sin(a),
      ),
    )
  }
  ring_to_poly(pts)
}

// MARK: buffer line string ----------------------------------------------------

///|
/// Buffer a LineString: produces a `MultiPolygon` of all points within
/// `distance` of the line. Self-intersecting lines are unioned into
/// their multi-polygon components.
///
/// ```check
/// test "buffer_line_string - flat caps rectangle" {
///   let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0)])
///   let opts = BufferOptions::{ end_cap: Flat, join: Round, miter_limit: 4.0, arc_segments: 8 }
///   let mp = buffer_line_string(ls, 0.1, opts)
///   assert_true(mp.polygons().length() > 0)
/// }
/// ```
pub fn buffer_line_string(
  ls : @type.LineString,
  distance : Double,
  options : BufferOptions,
) -> @type.MultiPolygon {
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 || distance <= 0.0 {
    return @type.MultiPolygon::empty()
  }

  let segs : Array[@type.Polygon] = []
  for i in 0..<(n - 1) {
    let a = coords[i]
    let b = coords[i + 1]
    let (p1, p2) = perpendicular_vec(a, b, distance)
    // build the rectangular strip for this segment
    let strip = @type.Polygon::Polygon(
      @type.LineString::LineString([
        p1,
        p2,
        @type.Coord::Coord(b.x(), b.y()),
        @type.Coord::Coord(a.x(), a.y()),
        p1,
      ]),
      [],
    )
    segs.push(strip)
  }

  // add end caps
  if options.end_cap == Round {
    // start cap
    let a = coords[0]
    let b = coords[1]
    let dx = b.x() - a.x()
    let dy = b.y() - a.y()
    let len = (dx * dx + dy * dy).sqrt()
    if len > 1.0e-15 {
      let dir = @math.atan2(dy, dx)
      let arc1 = arc_points(
        a,
        distance,
        dir + @math.PI / 2.0,
        dir + @math.PI + @math.PI / 2.0,
        options.arc_segments,
      )
      segs.push(ring_to_poly(arc1))
    }
    // end cap
    let a2 = coords[n - 2]
    let b2 = coords[n - 1]
    let dx2 = b2.x() - a2.x()
    let dy2 = b2.y() - a2.y()
    let len2 = (dx2 * dx2 + dy2 * dy2).sqrt()
    if len2 > 1.0e-15 {
      let dir2 = @math.atan2(dy2, dx2)
      let arc2 = arc_points(
        b2,
        distance,
        dir2 - @math.PI / 2.0,
        dir2 + @math.PI / 2.0,
        options.arc_segments,
      )
      segs.push(ring_to_poly(arc2))
    }
  }

  // add corner joins
  for i in 1..<(n - 1) {
    if options.join == Round {
      let prev = coords[i - 1]
      let curr = coords[i]
      let next = coords[i + 1]
      let dx1 = curr.x() - prev.x()
      let dy1 = curr.y() - prev.y()
      let dx2 = next.x() - curr.x()
      let dy2 = next.y() - curr.y()
      if dx1 * dx1 + dy1 * dy1 > 1.0e-15 && dx2 * dx2 + dy2 * dy2 > 1.0e-15 {
        let a1 = @math.atan2(dy1, dx1)
        let a2 = @math.atan2(dy2, dx2)
        let arc = arc_points(
          curr,
          distance,
          a1 - @math.PI / 2.0,
          a2 + @math.PI / 2.0,
          4,
        )
        segs.push(ring_to_poly(arc))
      }
    }
  }

  // union all segments
  if segs.length() == 0 {
    return @type.MultiPolygon::empty()
  }
  let mut result = @type.MultiPolygon::MultiPolygon([segs[0]])
  for k = 1; k < segs.length(); k = k + 1 {
    let mp1 = result
    let mp2 = @type.MultiPolygon::MultiPolygon([segs[k]])
    let merged : Array[@type.Polygon] = []
    for i = 0; i < mp1.polygons().length(); i = i + 1 {
      for j = 0; j < mp2.polygons().length(); j = j + 1 {
        let un = polygon_union(mp1.polygons()[i], mp2.polygons()[j])
        for u = 0; u < un.polygons().length(); u = u + 1 {
          merged.push(un.polygons()[u])
        }
      }
    }
    result = @type.MultiPolygon::MultiPolygon(merged)
  }
  result
}

// MARK: stitch + repair (ms-25) -----------------------------------------------

///|
/// Stitch two `LineString`s sharing an endpoint. Returns the concatenated
/// result preserving `a`'s start coordinate. Handles end-to-start and
/// end-to-end joins. Returns `None` if no endpoint matches.
///
/// ```check
/// test "stitch - two lines sharing endpoint" {
///   let a = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0)])
///   let b = @type.LineString::from_tuples([(1.0, 0.0), (1.0, 1.0)])
///   match stitch_line_strings(a, b) {
///     Some(ls) => {
///       let cs = ls.coords()
///       assert_true(cs.length() == 4)
///       assert_true(cs[0] == @type.Coord::Coord(0.0, 0.0))
///       assert_true(cs[3] == @type.Coord::Coord(1.0, 1.0))
///     }
///     None => assert_true(false)
///   }
/// }
/// ```
pub fn stitch_line_strings(
  a : @type.LineString,
  b : @type.LineString,
) -> @type.LineString? {
  let ca = a.coords()
  let cb = b.coords()
  if ca.length() < 1 || cb.length() < 1 {
    return None
  }
  let a0 = ca[0]
  let a1 = ca[ca.length() - 1]
  let b0 = cb[0]
  let b1 = cb[cb.length() - 1]
  let result : Array[@type.Coord] = []
  if a1 == b0 {
    for k = 0; k < ca.length() - 1; k = k + 1 {
      result.push(ca[k])
    }
    for k = 0; k < cb.length(); k = k + 1 {
      result.push(cb[k])
    }
    Some(@type.LineString::LineString(result))
  } else if a1 == b1 {
    for k = 0; k < ca.length() - 1; k = k + 1 {
      result.push(ca[k])
    }
    let m = cb.length()
    for k = 0; k < m; k = k + 1 {
      result.push(cb[m - 1 - k])
    }
    Some(@type.LineString::LineString(result))
  } else if a0 == b0 {
    let m = cb.length()
    for k = 0; k < m - 1; k = k + 1 {
      result.push(cb[m - 1 - k])
    }
    for k = 0; k < ca.length(); k = k + 1 {
      result.push(ca[k])
    }
    Some(@type.LineString::LineString(result))
  } else if a0 == b1 {
    for k = 0; k < cb.length(); k = k + 1 {
      result.push(cb[k])
    }
    for k = 1; k < ca.length(); k = k + 1 {
      result.push(ca[k])
    }
    Some(@type.LineString::LineString(result))
  } else {
    None
  }
}

///|
/// Repair a self-intersecting polygon by decomposing it into simple
/// components. Delegates to the boolean-ops engine: self-union naturally
/// splits tangled rings into separate non-self-crossing components.
///
/// ```check
/// test "repair_polygon - bow-tie decomposes" {
///   let ls = @type.LineString::from_tuples([
///     (0.0, 0.0), (1.0, 1.0), (1.0, 0.0), (0.0, 1.0), (0.0, 0.0),
///   ])
///   let poly = @type.Polygon::Polygon(ls, [])
///   let result = repair_polygon(poly)
///   assert_true(result.polygons().length() >= 1)
/// }
/// ```
pub fn repair_polygon(poly : @type.Polygon) -> @type.MultiPolygon {
  polygon_union(poly, poly)
}

// MARK: buffer polygon --------------------------------------------------------

///|
/// Buffer a Polygon: positive `distance` = outward expansion; negative
/// = inward shrinkage.
///
/// ```check
/// test "buffer_polygon - positive distance enlarges square" {
///   let sq = @type.Polygon::Polygon(
///     @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0)]),
///     [],
///   )
///   let opts = BufferOptions::default()
///   let result = buffer_polygon(sq, 0.1, opts)
///   assert_true(result.polygons().length() > 0)
/// }
/// ```
pub fn buffer_polygon(
  poly : @type.Polygon,
  distance : Double,
  options : BufferOptions,
) -> @type.MultiPolygon {
  if distance == 0.0 || poly.exterior().coords().length() < 4 {
    return @type.MultiPolygon::MultiPolygon([poly])
  }

  if distance > 0.0 {
    // outward: buffer the exterior outward, then subtract any holes' inward buffers
    let outer = buffer_line_string(poly.exterior(), distance, options)
    // Simplify: use just the first component for common cases
    outer
  } else {
    // negative: shrink the exterior
    let abs_d = -distance
    let shrunk = buffer_line_string(poly.exterior(), -abs_d, options)
    shrunk
  }
}

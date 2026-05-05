// Boolean operations on polygons.
//
// **Scope of this initial implementation**: this is a Sutherland-Hodgman
// polygon clipper, which correctly clips an **arbitrary subject polygon**
// against a **convex clip polygon**. It is sufficient for many common cases
// (clipping by a rectangle, by a triangle, by a half-plane), but does NOT
// handle:
//
// - Boolean operations between two arbitrary (potentially non-convex)
//   polygons in full generality (would require Greiner-Hormann or Vatti).
// - Polygons with holes (interiors are dropped during clipping).
// - Self-intersecting polygons.
//
// The full general-purpose boolean op algorithm (intersection / union /
// difference / xor on arbitrary multi-polygons) corresponds to the Rust
// `i_overlay` crate and remains future work.

///|
/// Returns whether `coord` lies on the interior side of the directed line
/// from `edge_start` to `edge_end`. Uses the right-hand rule: if the
/// clip polygon is given in CCW order, then "inside" means to the left of
/// each directed edge.
fn inside_edge(
  coord : @type.Coord,
  edge_start : @type.Coord,
  edge_end : @type.Coord,
) -> Bool {
  @robust.orient2d(edge_start, edge_end, coord) >= 0.0
}

///|
/// Computes the intersection of segment `s1 -> s2` with the line through
/// `e1 -> e2` (extended). Returns the intersection coordinate (assumes the
/// line is not parallel to the segment, which is checked at the call site
/// by the caller's "exit" condition).
fn line_line_intersection_extend(
  s1 : @type.Coord,
  s2 : @type.Coord,
  e1 : @type.Coord,
  e2 : @type.Coord,
) -> @type.Coord {
  let dc = e1 - e2
  let dp = s1 - s2
  let n1 = e1.x() * e2.y() - e1.y() * e2.x()
  let n2 = s1.x() * s2.y() - s1.y() * s2.x()
  let denom = dc.x() * dp.y() - dc.y() * dp.x()
  if denom == 0.0 {
    // Parallel — return midpoint as a fallback (shouldn't happen on a
    // well-formed clip).
    return @type.Coord::new((s1.x() + s2.x()) / 2.0, (s1.y() + s2.y()) / 2.0)
  }
  @type.Coord::new(
    (n1 * dp.x() - n2 * dc.x()) / denom,
    (n1 * dp.y() - n2 * dc.y()) / denom,
  )
}

///|
/// Clips the `subject` polygon by the `clip` polygon using the
/// Sutherland-Hodgman algorithm. Returns the intersection (subject ∩ clip)
/// as a new polygon. The clip polygon **must be convex and CCW**.
///
/// If `subject` lies entirely outside `clip`, returns an empty polygon
/// (exterior with 0 coordinates).
pub fn intersection_sutherland_hodgman(
  subject : @type.Polygon,
  clip : @type.Polygon,
) -> @type.Polygon {
  let mut output : Array[@type.Coord] = []
  let subject_coords = subject.exterior().coords()
  // Use the closed form (drop the trailing duplicate if present) for the
  // working list.
  for i = 0; i < subject_coords.length() - 1; i = i + 1 {
    output.push(subject_coords[i])
  }
  if subject_coords.length() > 0 &&
    subject_coords[0] != subject_coords[subject_coords.length() - 1] {
    // Add the last coord if the ring isn't auto-closed
    output.push(subject_coords[subject_coords.length() - 1])
  }
  let clip_coords = clip.exterior().coords()
  let n_clip = clip_coords.length()
  // Iterate clip edges (drop last clip coord if it equals the first)
  let clip_edge_count = if n_clip > 1 && clip_coords[0] == clip_coords[n_clip - 1] {
    n_clip - 1
  } else {
    n_clip
  }
  for i = 0; i < clip_edge_count; i = i + 1 {
    if output.length() == 0 {
      break
    }
    let e1 = clip_coords[i]
    let e2 = clip_coords[(i + 1) % clip_edge_count]
    let input = output
    output = []
    let m = input.length()
    if m == 0 {
      continue
    }
    let mut prev = input[m - 1]
    let mut prev_inside = inside_edge(prev, e1, e2)
    for k = 0; k < m; k = k + 1 {
      let current = input[k]
      let current_inside = inside_edge(current, e1, e2)
      if current_inside {
        if !prev_inside {
          output.push(line_line_intersection_extend(prev, current, e1, e2))
        }
        output.push(current)
      } else if prev_inside {
        output.push(line_line_intersection_extend(prev, current, e1, e2))
      }
      prev = current
      prev_inside = current_inside
    }
  }
  if output.length() == 0 {
    return @type.Polygon::new(@type.LineString::new([]), [])
  }
  @type.Polygon::new(@type.LineString::new(output), [])
}

///|
/// Clips a `subject` polygon by an axis-aligned rectangle. Returns the
/// intersection.
pub fn intersection_polygon_rect(
  subject : @type.Polygon,
  clip : @type.Rect,
) -> @type.Polygon {
  intersection_sutherland_hodgman(subject, clip.to_polygon())
}

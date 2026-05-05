// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/simplify_vw.rs
//
// Visvalingam-Whyatt: removes the coord with the smallest associated triangle
// area, then re-evaluates neighbouring triangles. Continues until the
// smallest remaining triangle exceeds `epsilon` (treated as an area).

///|
fn triangle_area_2x(
  a : @type.Coord,
  b : @type.Coord,
  c : @type.Coord,
) -> Double {
  ((b.x() - a.x()) * (c.y() - a.y()) - (b.y() - a.y()) * (c.x() - a.x())).abs()
}

///|
/// Simplifies a line string using the Visvalingam-Whyatt algorithm.
/// Points whose associated triangle has 2*area below `epsilon * 2` are
/// iteratively removed. (Note: the threshold here is direct area not
/// 2*area, matching geo's sense.)
pub fn simplify_vw_line_string(
  ls : @type.LineString,
  epsilon : Double,
) -> @type.LineString {
  let coords = ls.coords()
  if coords.length() < 3 {
    return ls
  }
  // Maintain a working list of indices into `coords` that are still kept.
  let kept = Array::makei(coords.length(), fn(i) { i })
  let area_threshold = epsilon * 2.0
  // Iteratively remove the coord with the smallest triangle area.
  let mut continue_loop = true
  while continue_loop && kept.length() > 2 {
    continue_loop = false
    let mut min_area = @double.infinity
    let mut min_index = -1
    for i = 1; i < kept.length() - 1; i = i + 1 {
      let area = triangle_area_2x(
        coords[kept[i - 1]],
        coords[kept[i]],
        coords[kept[i + 1]],
      )
      if area < min_area {
        min_area = area
        min_index = i
      }
    }
    if min_index >= 0 && min_area < area_threshold {
      let _ = kept.remove(min_index)
      continue_loop = true
    }
  }
  let result = Array::new(capacity=kept.length())
  for idx in kept {
    result.push(coords[idx])
  }
  @type.LineString::new(result)
}

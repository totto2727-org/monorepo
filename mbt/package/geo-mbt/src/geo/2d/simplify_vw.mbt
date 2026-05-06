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

///|
/// Removes the element at `idx` from `arr`, returning a new array. Pure:
/// `arr` is not mutated.
fn[T] array_dropped_at(arr : Array[T], idx : Int) -> Array[T] {
  Array::makei(arr.length() - 1, fn(k) {
    if k < idx {
      arr[k]
    } else {
      arr[k + 1]
    }
  })
}

///|
/// One pass of VW: finds the interior index whose triangle area is smallest,
/// and if it is below the threshold returns the kept-list with that index
/// dropped. Otherwise returns `None` to signal that the simplification has
/// converged.
fn vw_step(
  kept : Array[Int],
  coords : Array[@type.Coord],
  area_threshold : Double,
) -> Array[Int]? {
  if kept.length() <= 2 {
    return None
  }
  let acc = (1)
    .until(kept.length() - 1)
    .fold(init=(@double.infinity, -1), fn(acc, i) {
      let area = triangle_area_2x(
        coords[kept[i - 1]],
        coords[kept[i]],
        coords[kept[i + 1]],
      )
      if area < acc.0 {
        (area, i)
      } else {
        acc
      }
    })
  let (min_area, min_index) = acc
  if min_index >= 0 && min_area < area_threshold {
    Some(array_dropped_at(kept, min_index))
  } else {
    None
  }
}

///|
/// Tail-recursive driver — keeps reducing `kept` until `vw_step` reports no
/// further reduction is possible.
fn vw_simplify_indices(
  kept : Array[Int],
  coords : Array[@type.Coord],
  area_threshold : Double,
) -> Array[Int] {
  match vw_step(kept, coords, area_threshold) {
    Some(next) => vw_simplify_indices(next, coords, area_threshold)
    None => kept
  }
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
  let initial = Array::makei(coords.length(), fn(i) { i })
  let kept = vw_simplify_indices(initial, coords, epsilon * 2.0)
  @type.LineString::LineString(kept.map(fn(idx) { coords[idx] }))
}

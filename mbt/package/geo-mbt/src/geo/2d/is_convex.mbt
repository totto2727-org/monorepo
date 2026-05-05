// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/is_convex.rs

///|
/// Returns `Some(true)` if the linestring is convex, `Some(false)` if not,
/// and `None` if the linestring has too few coords or is degenerate.
///
/// `strict = true` requires the strict variant: no three consecutive coords
/// may be collinear. The default `is_convex` uses `strict = false`.
pub fn is_convex(ls : @type.LineString) -> Bool {
  is_convex_with_strictness(ls, false)
}

///|
pub fn is_strictly_convex(ls : @type.LineString) -> Bool {
  is_convex_with_strictness(ls, true)
}

///|
fn is_convex_with_strictness(ls : @type.LineString, strict : Bool) -> Bool {
  let coords = ls.coords()
  // Use a closed view: if the first and last coords are equal, drop the last.
  let n = coords.length()
  let effective_n = if n > 1 && coords[0] == coords[n - 1] { n - 1 } else { n }
  if effective_n < 3 {
    return false
  }
  let mut sign : Int = 0 // 0=unset, +1=ccw, -1=cw
  for i = 0; i < effective_n; i = i + 1 {
    let p = coords[i]
    let q = coords[(i + 1) % effective_n]
    let r = coords[(i + 2) % effective_n]
    let det = @robust.orient2d(p, q, r)
    if det == 0.0 {
      if strict {
        return false
      }
      continue
    }
    let current_sign = if det > 0.0 { 1 } else { -1 }
    if sign == 0 {
      sign = current_sign
    } else if sign != current_sign {
      return false
    }
  }
  true
}

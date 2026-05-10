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

///|
/// Per-vertex orientation outcome for the convexity fold:
/// `Skip` keeps the running sign unchanged (collinear, non-strict mode);
/// `Sign` carries +1 / -1 for CCW / CW; `Fail` short-circuits to `false`.
priv enum ConvexStep {
  Skip
  Sign(Int)
  Fail
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
  // Fold returns `Some(running_sign)` if the polygon stayed convex so far
  // (where `running_sign = 0` means no non-collinear triple seen yet) and
  // `None` once a sign flip / collinear-strict failure is detected.
  let result = (0)
    .until(effective_n)
    .fold(init=Some(0), fn(acc : Int?, i : Int) {
      match acc {
        None => None
        Some(sign) => {
          let p = coords[i]
          let q = coords[(i + 1) % effective_n]
          let r = coords[(i + 2) % effective_n]
          let det = @robust.orient2d(p, q, r)
          let step : ConvexStep = if det == 0.0 {
            if strict {
              Fail
            } else {
              Skip
            }
          } else if det > 0.0 {
            Sign(1)
          } else {
            Sign(-1)
          }
          match step {
            Fail => None
            Skip => Some(sign)
            Sign(s) => if sign == 0 || sign == s { Some(s) } else { None }
          }
        }
      }
    })
  result is Some(_)
}

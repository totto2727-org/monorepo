// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/chaikin_smoothing.rs

///|
/// Performs one iteration of Chaikin smoothing: each segment `(p_i, p_{i+1})`
/// becomes two new coords at 1/4 and 3/4 along the segment. Repeated for
/// `n_iterations` rounds. The first and last coords are preserved for open
/// linestrings; closed linestrings smooth uniformly.
pub fn chaikin_smoothing(
  ls : @type.LineString,
  n_iterations : Int,
) -> @type.LineString {
  let mut current = ls
  for i = 0; i < n_iterations; i = i + 1 {
    current = chaikin_step(current)
  }
  current
}

///|
fn chaikin_step(ls : @type.LineString) -> @type.LineString {
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return ls
  }
  let is_closed = coords[0] == coords[n - 1]
  // Each of the (n-1) segments contributes 2 cut-points (q1 at 1/4, q2 at
  // 3/4). Build them all in one Array::makei pass: index j ∈ [0, 2(n-1))
  // maps to segment i = j / 2 and side k = j % 2.
  let cuts = Array::makei(2 * (n - 1), fn(j) {
    let i = j / 2
    let p = coords[i]
    let q = coords[i + 1]
    if j % 2 == 0 {
      @type.Coord(0.75 * p.x() + 0.25 * q.x(), 0.75 * p.y() + 0.25 * q.y())
    } else {
      @type.Coord(0.25 * p.x() + 0.75 * q.x(), 0.25 * p.y() + 0.75 * q.y())
    }
  })
  let result = if is_closed {
    // Closed ring: smooth uniformly + repeat the first cut as the closing
    // coord (so first == last).
    [..cuts, cuts[0]]
  } else {
    // Open: prepend original first coord, append original last coord.
    [coords[0], ..cuts, coords[n - 1]]
  }
  @type.LineString::LineString(result)
}

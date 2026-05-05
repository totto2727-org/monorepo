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
  let result : Array[@type.Coord] = []
  if !is_closed {
    result.push(coords[0])
  }
  for i = 0; i < n - 1; i = i + 1 {
    let p = coords[i]
    let q = coords[i + 1]
    let q1 = @type.Coord::new(
      0.75 * p.x() + 0.25 * q.x(),
      0.75 * p.y() + 0.25 * q.y(),
    )
    let q2 = @type.Coord::new(
      0.25 * p.x() + 0.75 * q.x(),
      0.25 * p.y() + 0.75 * q.y(),
    )
    result.push(q1)
    result.push(q2)
  }
  if !is_closed {
    result.push(coords[n - 1])
  } else {
    // Close the smoothed ring
    result.push(result[0])
  }
  @type.LineString::new(result)
}

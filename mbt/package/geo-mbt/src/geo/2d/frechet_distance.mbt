// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/frechet_distance.rs

///|
/// Pointwise `max` for `Double`.
fn dmax(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Pointwise `min` for `Double`.
fn dmin(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// First DP row (`i = 0`): a running max along the second linestring.
fn frechet_first_row(
  coords_a : Array[@type.Coord],
  coords_b : Array[@type.Coord],
) -> Array[Double] {
  let m = coords_b.length()
  let cell0 = euclidean_distance_coords(coords_a[0], coords_b[0])
  (1)
  .until(m)
  .fold(init=[cell0], fn(row, j) {
    let prev = row[row.length() - 1]
    [..row, dmax(prev, euclidean_distance_coords(coords_a[0], coords_b[j]))]
  })
}

///|
/// Computes row `i` (i > 0) of the Fréchet DP table given the previous row.
/// `new_row[0] = max(prev_row[0], dist(a[i], b[0]))`; for `j > 0`,
/// `new_row[j] = max(min(prev_row[j], new_row[j-1], prev_row[j-1]),
///                  dist(a[i], b[j]))`.
fn frechet_next_row(
  prev_row : Array[Double],
  i : Int,
  coords_a : Array[@type.Coord],
  coords_b : Array[@type.Coord],
) -> Array[Double] {
  let m = coords_b.length()
  let cell0 = dmax(
    prev_row[0],
    euclidean_distance_coords(coords_a[i], coords_b[0]),
  )
  (1)
  .until(m)
  .fold(init=[cell0], fn(row, j) {
    let best_prev = dmin(
      dmin(prev_row[j], row[row.length() - 1]),
      prev_row[j - 1],
    )
    [
      ..row,
      dmax(best_prev, euclidean_distance_coords(coords_a[i], coords_b[j])),
    ]
  })
}

///|
/// Discrete Fréchet distance between two `LineString`s. Returns 0 for two
/// empty linestrings; returns `infinity` if exactly one is empty.
pub fn frechet_distance(a : @type.LineString, b : @type.LineString) -> Double {
  let coords_a = a.coords()
  let coords_b = b.coords()
  if coords_a.length() == 0 && coords_b.length() == 0 {
    return 0.0
  }
  if coords_a.length() == 0 || coords_b.length() == 0 {
    return @double.infinity
  }
  let n = coords_a.length()
  let m = coords_b.length()
  let initial = frechet_first_row(coords_a, coords_b)
  let final_row = (1)
    .until(n)
    .fold(init=initial, fn(prev_row, i) {
      frechet_next_row(prev_row, i, coords_a, coords_b)
    })
  final_row[m - 1]
}

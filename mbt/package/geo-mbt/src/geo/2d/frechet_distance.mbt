// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/frechet_distance.rs

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
  // ca[i][j] = the discrete Fréchet distance up to coords_a[i], coords_b[j].
  let ca = Array::makei(n, fn(_) { Array::make(m, -1.0) })
  ca[0][0] = euclidean_distance_coords(coords_a[0], coords_b[0])
  for i = 1; i < n; i = i + 1 {
    let prev = ca[i - 1][0]
    let dist = euclidean_distance_coords(coords_a[i], coords_b[0])
    ca[i][0] = if prev > dist { prev } else { dist }
  }
  for j = 1; j < m; j = j + 1 {
    let prev = ca[0][j - 1]
    let dist = euclidean_distance_coords(coords_a[0], coords_b[j])
    ca[0][j] = if prev > dist { prev } else { dist }
  }
  for i = 1; i < n; i = i + 1 {
    for j = 1; j < m; j = j + 1 {
      let mut best_prev = ca[i - 1][j]
      if ca[i][j - 1] < best_prev {
        best_prev = ca[i][j - 1]
      }
      if ca[i - 1][j - 1] < best_prev {
        best_prev = ca[i - 1][j - 1]
      }
      let dist = euclidean_distance_coords(coords_a[i], coords_b[j])
      ca[i][j] = if best_prev > dist { best_prev } else { dist }
    }
  }
  ca[n - 1][m - 1]
}

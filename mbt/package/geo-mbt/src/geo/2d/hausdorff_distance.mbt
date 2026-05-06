// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/hausdorff_distance.rs

///|
/// Returns the maximum distance from any coord in `from` to its nearest coord
/// in `to`.
fn directed_hausdorff(
  from : Array[@type.Coord],
  to : Array[@type.Coord],
) -> Double {
  if from.length() == 0 || to.length() == 0 {
    return @double.infinity
  }
  from
  .iter()
  .fold(init=0.0, fn(max_dist, a) {
    let min_dist = to
      .iter()
      .fold(init=@double.infinity, fn(acc, b) {
        let d = euclidean_distance_coords(a, b)
        if d < acc {
          d
        } else {
          acc
        }
      })
    if min_dist > max_dist {
      min_dist
    } else {
      max_dist
    }
  })
}

///|
/// Hausdorff distance between two arrays of coordinates: the maximum, in
/// either direction, of the distance from any coord in one set to its nearest
/// in the other.
pub fn hausdorff_distance_coords(
  a : Array[@type.Coord],
  b : Array[@type.Coord],
) -> Double {
  let h1 = directed_hausdorff(a, b)
  let h2 = directed_hausdorff(b, a)
  if h1 > h2 {
    h1
  } else {
    h2
  }
}

///|
/// Hausdorff distance between two geometries via their full coord arrays.
pub fn hausdorff_distance_geometry(
  a : @type.Geometry,
  b : @type.Geometry,
) -> Double {
  hausdorff_distance_coords(coords_of_geometry(a), coords_of_geometry(b))
}

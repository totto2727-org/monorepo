///|
pub enum PointInPolygonResult {
  Inside
  Outside
  Boundary
} derive(Show, Eq)

///|
pub fn[Coord : @type.Coord2DTrait, Ring : @type.RingTrait] point_in_ring(
  position : Coord,
  ring : Ring,
) -> PointInPolygonResult {
  let position = position.xy()
  let ring = ring.coord_array()
  let mut current = ring[0].xy()
  let mut diff1 = current - position
  let mut k = 0
  for coord in ring[1:] {
    let coord = coord.xy()
    let diff2 = coord - position
    if diff1.y == 0.0 && diff2.y == 0.0 {
      if (diff2.x <= 0.0 && diff1.x >= 0.0) ||
        (diff1.x <= 0.0 && diff2.x >= 0.0) {
        return PointInPolygonResult::Boundary
      }
    } else if (diff2.y >= 0.0 && diff1.y <= 0.0) ||
      (diff2.y <= 0.0 && diff1.y >= 0.0) {
      let f = @robust.orient2d(diff1, diff2, @type.XY::new(0.0, 0.0))
      if f == 0.0 {
        return PointInPolygonResult::Boundary
      }
      if (f > 0.0 && diff2.y > 0.0 && diff1.y <= 0.0) ||
        (f < 0.0 && diff2.y <= 0.0 && diff1.y > 0.0) {
        k += 1
      }
    }
    current = coord
    diff1 = diff2
  }
  if k % 2 == 0 {
    PointInPolygonResult::Outside
  } else {
    PointInPolygonResult::Inside
  }
}

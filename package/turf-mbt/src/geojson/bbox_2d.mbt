///|
pub struct BBox2D {
  min : Position2D
  max : Position2D
} derive(Show, Eq, Compare, Hash)

///|
pub fn BBox2D::new(min : Position2D, max : Position2D) -> BBox2D {
  BBox2D::{ min, max }
}

///|
pub(all) suberror EmptyPositionsError String derive(Show, Eq, Compare, Hash)

///|
pub fn BBox2D::from_positions(
  positions : Array[Position2D],
) -> BBox2D raise EmptyPositionsError {
  let min_x = positions.fold(
    init=positions
      .get(0)
      .unwrap_or_error(EmptyPositionsError("Positions array is empty")).x,
    (mix, position) => @cmp.minimum(mix, position.x),
  )
  let min_y = positions.fold(
    init=positions
      .get(0)
      .unwrap_or_error(EmptyPositionsError("Positions array is empty")).y,
    (mix, position) => @cmp.minimum(mix, position.y),
  )
  let max_x = positions.fold(
    init=positions
      .get(0)
      .unwrap_or_error(EmptyPositionsError("Positions array is empty")).x,
    (mix, position) => @cmp.maximum(mix, position.x),
  )
  let max_y = positions.fold(
    init=positions
      .get(0)
      .unwrap_or_error(EmptyPositionsError("Positions array is empty")).y,
    (mix, position) => @cmp.maximum(mix, position.y),
  )
  BBox2D::new(Position2D::new((min_x, min_y)), Position2D::new((max_x, max_y)))
}

///|
/// Identity Implementation
pub impl ToBBox for BBox2D with to_bbox(self) {
  BBox::BBox2D(self)
}

///|
pub impl ToJson for BBox2D with to_json(self) {
  [self.min.x, self.min.y, self.max.x, self.max.y]
}

///|
pub impl FromJson for BBox2D with from_json(json, path) {
  match json {
    Array(
      [
        Number(min_x, ..),
        Number(min_y, ..),
        Number(max_x, ..),
        Number(max_y, ..),
      ]
    ) =>
      BBox2D::new(
        Position2D::new((min_x, min_y)),
        Position2D::new((max_x, max_y)),
      )
    _ => raise @json.JsonDecodeError((path, "Invalid BBox"))
  }
}

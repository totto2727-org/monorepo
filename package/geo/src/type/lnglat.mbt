///|
pub trait LngLatTrait: Coord2DTrait {
  to_degrees(Self) -> Self
  to_radians(Self) -> Self
}

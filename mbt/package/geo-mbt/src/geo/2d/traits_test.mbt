// Tests for the trait abstractions.

///|
test "CoordsCarrier trait dispatches to per-type impls" {
  let p : @type.Point = @type.Point::new(1.0, 2.0)
  let coords = CoordsCarrier::coords(p)
  assert_eq(coords.length(), 1)
}

///|
test "Bounded trait works on every variant" {
  let pt : @type.Point = @type.Point::new(1.0, 2.0)
  assert_true(Bounded::bbox(pt) != None)
  let mp_empty = @type.MultiPoint::new([])
  assert_true(Bounded::bbox(mp_empty) == None)
}

///|
test "HasArea trait on rect" {
  let r = @type.Rect::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(3.0, 4.0))
  assert_eq(HasArea::signed_area(r), 12.0)
  assert_eq(HasArea::unsigned_area(r), 12.0)
}

///|
test "HasCentroid trait on polygon" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (4.0, 0.0),
    (4.0, 4.0),
    (0.0, 4.0),
  ])
  let p = @type.Polygon::new(exterior, [])
  let c = HasCentroid::centroid(p).unwrap()
  assert_true((c.x() - 2.0).abs() < 1.0e-9)
  assert_true((c.y() - 2.0).abs() < 1.0e-9)
}

///|
test "HasLength trait on line string" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (3.0, 0.0),
    (3.0, 4.0),
  ])
  assert_eq(HasLength::euclidean_length(ls), 7.0)
}

///|
/// Demonstrates that the trait can be used as a generic constraint, the
/// primary motivating use case for these abstractions.
fn[B : Bounded] enclosing_box(items : Array[B]) -> @type.Rect? {
  let mut current : @type.Rect? = None
  for item in items {
    match Bounded::bbox(item) {
      None => continue
      Some(b) =>
        match current {
          None => current = Some(b)
          Some(c) => {
            let merged_min = @type.Coord::new(
              if c.min().x() < b.min().x() { c.min().x() } else { b.min().x() },
              if c.min().y() < b.min().y() { c.min().y() } else { b.min().y() },
            )
            let merged_max = @type.Coord::new(
              if c.max().x() > b.max().x() { c.max().x() } else { b.max().x() },
              if c.max().y() > b.max().y() { c.max().y() } else { b.max().y() },
            )
            current = Some(@type.Rect::new(merged_min, merged_max))
          }
        }
    }
  }
  current
}

///|
test "generic Bounded constraint usage" {
  let points = [
    @type.Point::new(0.0, 0.0),
    @type.Point::new(3.0, 4.0),
    @type.Point::new(-1.0, 2.0),
  ]
  let bbox = enclosing_box(points).unwrap()
  assert_eq(bbox.min().x(), -1.0)
  assert_eq(bbox.max().x(), 3.0)
  assert_eq(bbox.min().y(), 0.0)
  assert_eq(bbox.max().y(), 4.0)
}

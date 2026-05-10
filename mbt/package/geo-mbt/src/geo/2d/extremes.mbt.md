# extremes.mbt

Cardinal-direction extremes (`x_min` / `x_max` / `y_min` / `y_max`) of a coordinate set, returned as an `Outcome` struct (or `None` if the input is empty). The trait `HasExtremes::extremes` lifts this to whole `Geometry` values.

## Public API

- `Outcome`
- `Outcome::Outcome`
- `extremes_of_coords`
- `HasExtremes` — `extremes` (impls in this file)

## Test

### `Outcome::Outcome`

- Simple initialization

```mbt check
///|
test "Outcome::Outcome - simple initialization" {
  let o = Outcome::Outcome(
    @type.Coord::Coord(-1.0, 5.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(-1.0, 5.0),
  )
  debug_inspect(
    o,
    content=(
      #|{
      #|  x_min: { x: -1, y: 5 },
      #|  x_max: { x: 4, y: 0 },
      #|  y_min: { x: 4, y: 0 },
      #|  y_max: { x: -1, y: 5 },
      #|}
    ),
  )
}
```

### `extremes_of_coords`

| Variable | State       | Note                |  1  |  2  |
| :------- | :---------- | :------------------ | :-: | :-: |
| `coords` | `Empty`     | returns `None`      |  ✓  |     |
| `coords` | `Non-empty` | returns `Some(...)` |     |  ✓  |

- Empty input returns `None`

```mbt check
///|
test "extremes_of_coords - empty returns None" {
  @test.assert_eq(extremes_of_coords([]), None)
}
```

- Non-empty input returns the four cardinal-extreme coords

```mbt check
///|
test "extremes_of_coords - returns x_min, x_max, y_min, y_max" {
  let coords = [
    @type.Coord::Coord(1.0, 5.0),
    @type.Coord::Coord(3.0, 2.0),
    @type.Coord::Coord(-1.0, 7.0),
    @type.Coord::Coord(4.0, 0.0),
  ]
  @test.assert_eq(
    extremes_of_coords(coords),
    Some(
      Outcome::Outcome(
        @type.Coord::Coord(-1.0, 7.0),
        @type.Coord::Coord(4.0, 0.0),
        @type.Coord::Coord(4.0, 0.0),
        @type.Coord::Coord(-1.0, 7.0),
      ),
    ),
  )
}
```

### `HasExtremes`

#### `extremes`

- Direct dispatch on every concrete type

```mbt check
///|
test "HasExtremes::extremes - direct dispatch on every concrete type" {
  let pt = @type.Point::Point(0.0, 0.0)
  let l = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (3.0, 4.0)])
  let mls = @type.MultiLineString::MultiLineString([ls])
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (4.0, 0.0),
      (4.0, 4.0),
      (0.0, 4.0),
    ]),
    [],
  )
  let mpoly = @type.MultiPolygon::MultiPolygon([polygon])
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 1.0),
  )
  let tri = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(1.0, 0.0),
    @type.Coord::Coord(0.0, 1.0),
  )
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Point(pt),
  ])
  assert_true(HasExtremes::extremes(pt) is Some(_))
  assert_true(HasExtremes::extremes(l) is Some(_))
  assert_true(HasExtremes::extremes(ls) is Some(_))
  assert_true(HasExtremes::extremes(mp) is Some(_))
  assert_true(HasExtremes::extremes(mls) is Some(_))
  assert_true(HasExtremes::extremes(polygon) is Some(_))
  assert_true(HasExtremes::extremes(mpoly) is Some(_))
  assert_true(HasExtremes::extremes(r) is Some(_))
  assert_true(HasExtremes::extremes(tri) is Some(_))
  assert_true(HasExtremes::extremes(gc) is Some(_))
}
```

- Lifts `extremes_of_coords` to a `Geometry::LineString`

```mbt check
///|
test "HasExtremes::extremes - LineString cardinal extremes" {
  let ls = @type.LineString::from_tuples([
    (1.0, 5.0),
    (3.0, 2.0),
    (-1.0, 7.0),
    (4.0, 0.0),
  ])
  let outcome = match HasExtremes::extremes(@type.Geometry::LineString(ls)) {
    Some(o) => o
    None => abort("expected Some for non-empty LineString")
  }
  @test.assert_eq(outcome.x_min.x(), -1.0)
  @test.assert_eq(outcome.x_max.x(), 4.0)
  @test.assert_eq(outcome.y_min.y(), 0.0)
  @test.assert_eq(outcome.y_max.y(), 7.0)
}
```

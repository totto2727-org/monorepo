# area.mbt

Planar (signed and unsigned) area for `Polygon`, `MultiPolygon`, `Rect`, `Triangle`, and `Geometry`, exposed via the `HasArea` trait. The internal shoelace primitive `twice_signed_ring_area` is package-private (whitebox-tested in `area_wbtest.mbt`) — external callers should construct a `Polygon` from the ring and call `HasArea::signed_area` instead.

## Public API

- `HasArea` — impls on `Polygon` / `MultiPolygon` / `Rect` / `Triangle` / `Geometry`
  - `signed_area`
  - `unsigned_area`

## Test

### `HasArea`

#### `signed_area`

| Variable | State                             | Note                                   |  1  |  2  |  3  |  4  |  5  |
| :------- | :-------------------------------- | :------------------------------------- | :-: | :-: | :-: | :-: | :-: |
| `self`   | `Polygon (CCW)`                   | positive                               |  ✓  |     |     |     |     |
| `self`   | `Polygon (CW)`                    | negative                               |     |  ✓  |     |     |     |
| `self`   | `Polygon with hole`               | exterior area minus interior           |     |     |  ✓  |     |     |
| `self`   | `Rect`                            | `width * height`                       |     |     |     |  ✓  |     |
| `self`   | `Geometry::Point/Line/LineString` | zero-dimensional / one-dimensional → 0 |     |     |     |     |  ✓  |

- Polygon (CCW exterior): positive

```mbt check
///|
test "HasArea::signed_area - Polygon CCW positive" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
    (0.0, 0.0),
  ])
  @test.assert_eq(
    HasArea::signed_area(@type.Polygon::Polygon(exterior, [])),
    30.0,
  )
}
```

- Polygon (CW exterior): negative

```mbt check
///|
test "HasArea::signed_area - Polygon CW negative" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 6.0),
    (5.0, 6.0),
    (5.0, 0.0),
    (0.0, 0.0),
  ])
  @test.assert_eq(
    HasArea::signed_area(@type.Polygon::Polygon(exterior, [])),
    -30.0,
  )
}
```

- Polygon with hole: exterior area minus interior

```mbt check
///|
test "HasArea::signed_area - Polygon with hole subtracts interior area" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
    (0.0, 0.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
    (3.0, 3.0),
  ])
  @test.assert_eq(
    HasArea::signed_area(@type.Polygon::Polygon(exterior, [interior])),
    100.0 - 16.0,
  )
}
```

- Rect: `width * height`

```mbt check
///|
test "HasArea::signed_area - Rect is width * height" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(3.0, 4.0),
  )
  @test.assert_eq(HasArea::signed_area(r), 12.0)
}
```

- `Geometry` variants below 2D have area zero

```mbt check
///|
test "HasArea::signed_area - sub-2D Geometry variants have area zero" {
  let p = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  let l = @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  let ls = @type.Geometry::LineString(
    @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  @test.assert_eq(HasArea::signed_area(p), 0.0)
  @test.assert_eq(HasArea::signed_area(l), 0.0)
  @test.assert_eq(HasArea::signed_area(ls), 0.0)
}
```

#### `unsigned_area`

| Variable | State                   | Note              |  1  |  2  |
| :------- | :---------------------- | :---------------- | :-: | :-: |
| `self`   | `Polygon (any winding)` | `\|signed_area\|` |  ✓  |     |
| `self`   | `Right Triangle`        | `\|signed_area\|` |     |  ✓  |

- Polygon: `|signed_area|` regardless of winding

```mbt check
///|
test "HasArea::unsigned_area - Polygon equals abs of signed_area" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 6.0),
    (5.0, 6.0),
    (5.0, 0.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  @test.assert_eq(HasArea::unsigned_area(polygon), 30.0)
}
```

- Triangle: `|signed_area|`

```mbt check
///|
test "HasArea::unsigned_area - right triangle with legs 4 and 6 is 12" {
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(0.0, 6.0),
  )
  @test.assert_eq(HasArea::unsigned_area(t), 12.0)
}
```

- MultiPolygon: signed and unsigned direct dispatch

```mbt check
///|
test "HasArea - MultiPolygon direct dispatch (signed and unsigned)" {
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (5.0, 0.0),
      (5.0, 6.0),
      (0.0, 6.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  @test.assert_eq(HasArea::signed_area(mp), 30.0)
  @test.assert_eq(HasArea::unsigned_area(mp), 30.0)
}
```

- Rect: `unsigned_area` direct dispatch

```mbt check
///|
test "HasArea::unsigned_area - Rect direct dispatch" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(3.0, 4.0),
  )
  @test.assert_eq(HasArea::unsigned_area(r), 12.0)
}
```

- Triangle: `signed_area` direct dispatch

```mbt check
///|
test "HasArea::signed_area - Triangle direct dispatch" {
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(0.0, 6.0),
  )
  // CCW triangle: positive signed area = unsigned area = 12.
  @test.assert_eq(HasArea::signed_area(t), 12.0)
}
```

- `Geometry::unsigned_area` dispatch on every 2-D variant

```mbt check
///|
test "HasArea::unsigned_area - Geometry dispatch sweep over 2-D variants" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (5.0, 0.0),
    (5.0, 6.0),
    (0.0, 6.0),
    (0.0, 0.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  // Polygon dispatch.
  @test.assert_eq(
    HasArea::unsigned_area(@type.Geometry::Polygon(polygon)),
    30.0,
  )
  // MultiPolygon dispatch (sum of polygon areas).
  let mp = @type.MultiPolygon::MultiPolygon([polygon])
  @test.assert_eq(
    HasArea::unsigned_area(@type.Geometry::MultiPolygon(mp)),
    30.0,
  )
  // Rect dispatch.
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(3.0, 4.0),
  )
  @test.assert_eq(HasArea::unsigned_area(@type.Geometry::Rect(r)), 12.0)
  // Triangle dispatch via Geometry.
  let t = @type.Triangle::Triangle(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(4.0, 0.0),
    @type.Coord::Coord(0.0, 6.0),
  )
  @test.assert_eq(HasArea::unsigned_area(@type.Geometry::Triangle(t)), 12.0)
  // GeometryCollection dispatch (sum of components).
  let gc = @type.GeometryCollection::GeometryCollection([
    @type.Geometry::Polygon(polygon),
    @type.Geometry::Rect(r),
  ])
  @test.assert_eq(
    HasArea::unsigned_area(@type.Geometry::GeometryCollection(gc)),
    42.0,
  )
}
```

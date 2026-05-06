# coords_iter.mbt

Iterates the coordinates of every concrete geometry plus the dispatch over `Geometry`. Exposed via the `CoordsCarrier::coords` and `ExteriorCoordsCarrier::exterior_coords` traits (the latter excludes interior rings for `Polygon` / `MultiPolygon`). The single public free helper is `coords_count`, which returns the cardinality.

## Public API

- `coords_count`
- `CoordsCarrier` — `coords` (impls in traits.mbt for every geometry type)
- `ExteriorCoordsCarrier` — `exterior_coords` (impls in traits.mbt)

## Test

### `coords_count`

| Variable | State                  | Note                |  1  |  2  |
| :------- | :--------------------- | :------------------ | :-: | :-: |
| `g`      | `Geometry::Point`      | 1                   |  ✓  |     |
| `g`      | `Geometry::MultiPoint` | matches inner count |     |  ✓  |

- Counts a `Geometry::Point`'s single coord

```mbt check
///|
test "coords_count - Point has one coord" {
  let g = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
  @test.assert_eq(coords_count(g), 1)
}
```

- Counts a `Geometry::MultiPoint`'s coords

```mbt check
///|
test "coords_count - MultiPoint counts inner points" {
  let mp = @type.MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  @test.assert_eq(coords_count(@type.Geometry::MultiPoint(mp)), 3)
}
```

### `CoordsCarrier`

#### `coords`

| Variable | State              | Note                                  |  1  |  2  |  3  |
| :------- | :----------------- | :------------------------------------ | :-: | :-: | :-: |
| `self`   | `Point`            | `[coord]`                             |  ✓  |     |     |
| `self`   | `MultiPoint`       | preserves order                       |     |  ✓  |     |
| `self`   | `Polygon`          | walks exterior then every interior    |     |     |  ✓  |

- Point yields its single coord

```mbt check
///|
test "CoordsCarrier::coords - Point yields its coord" {
  let p = @type.Point::Point(1.0, 2.0)
  @test.assert_eq(CoordsCarrier::coords(p), [@type.Coord::Coord(1.0, 2.0)])
}
```

- MultiPoint preserves order

```mbt check
///|
test "CoordsCarrier::coords - MultiPoint preserves order" {
  let mp = @type.MultiPoint::from_tuples([
    (-10.0, 0.0),
    (20.0, 20.0),
    (30.0, 40.0),
  ])
  @test.assert_eq(CoordsCarrier::coords(mp), [
    @type.Coord::Coord(-10.0, 0.0),
    @type.Coord::Coord(20.0, 20.0),
    @type.Coord::Coord(30.0, 40.0),
  ])
}
```

- Polygon walks exterior then every interior — `coords()` is strictly larger than `exterior_coords()`

```mbt check
///|
test "CoordsCarrier::coords - Polygon walks exterior then interiors" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = @type.LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [interior])
  let all_coords = CoordsCarrier::coords(polygon)
  let exterior_coords = ExteriorCoordsCarrier::exterior_coords(polygon)
  assert_true(all_coords.length() > exterior_coords.length())
}
```

- Dispatch sweep across every variant: each impl returns the right cardinality

```mbt check
///|
test "CoordsCarrier::coords - dispatch covers every variant cardinality" {
  // Line: 2 coords.
  @test.assert_eq(
    CoordsCarrier::coords(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))).length(),
    2,
  )
  // LineString: matches input length.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)]),
    ).length(),
    3,
  )
  // MultiLineString: sum of component lengths.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.MultiLineString::MultiLineString([
        @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
        @type.LineString::from_tuples([(2.0, 0.0), (3.0, 1.0)]),
      ]),
    ).length(),
    4,
  )
  // MultiPolygon: 5 coords per polygon (after auto-close).
  let polygon = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  @test.assert_eq(
    CoordsCarrier::coords(@type.MultiPolygon::MultiPolygon([polygon])).length(),
    5,
  )
  // Rect: 4 corners.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.Rect::Rect(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(1.0, 1.0),
      ),
    ).length(),
    4,
  )
  // Triangle: 3 vertices.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.Triangle::Triangle(
        @type.Coord::Coord(0.0, 0.0),
        @type.Coord::Coord(1.0, 0.0),
        @type.Coord::Coord(0.0, 1.0),
      ),
    ).length(),
    3,
  )
  // GeometryCollection: sum of component coord counts.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.GeometryCollection::GeometryCollection([
        @type.Geometry::Point(@type.Point::Point(0.0, 0.0)),
        @type.Geometry::Point(@type.Point::Point(1.0, 1.0)),
      ]),
    ).length(),
    2,
  )
  // Geometry::Line dispatch: 2 coords.
  @test.assert_eq(
    CoordsCarrier::coords(
      @type.Geometry::Line(@type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))),
    ).length(),
    2,
  )
}
```

### `ExteriorCoordsCarrier`

#### `exterior_coords`

- Polygon's exterior alone is the auto-closed exterior ring (5 coords for a 4-coord input)

```mbt check
///|
test "ExteriorCoordsCarrier::exterior_coords - Polygon yields auto-closed exterior ring" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  @test.assert_eq(ExteriorCoordsCarrier::exterior_coords(polygon).length(), 5)
}
```

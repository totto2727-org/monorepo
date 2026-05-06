# bool_ops.mbt

Polygon clipping via Sutherland-Hodgman. The clip polygon must be **convex and CCW**; the subject may be arbitrary (interior holes are dropped during clipping; full general-purpose boolean ops on multi-polygons remain future work).

## Public API

- `intersection_sutherland_hodgman`
- `intersection_polygon_rect`

## Test

### `intersection_polygon_rect`

| Variable    | State                              | Note                                    |  1  |  2  |  3  |  4  |
| :---------- | :--------------------------------- | :-------------------------------------- | :-: | :-: | :-: | :-: |
| `subject`/`clip` | `Subject ⊆ clip`              | result equals subject area              |  ✓  |     |     |     |
| `subject`/`clip` | `Clip ⊆ subject`              | result equals clip area                 |     |  ✓  |     |     |
| `subject`/`clip` | `Half overlap`                | half of subject area                    |     |     |  ✓  |     |
| `subject`/`clip` | `Disjoint`                    | zero area                               |     |     |     |  ✓  |

- Subject fully inside clip: result equals subject area

```mbt check
///|
test "intersection_polygon_rect - subject inside clip equals subject area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (2.0, 2.0),
      (4.0, 2.0),
      (4.0, 4.0),
      (2.0, 4.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  @test.assert_eq(
    HasArea::unsigned_area(intersection_polygon_rect(subject, clip)),
    4.0,
  )
}
```

- Clip fully inside subject: result equals clip area

```mbt check
///|
test "intersection_polygon_rect - clip inside subject equals clip area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(2.0, 2.0),
    @type.Coord::Coord(4.0, 4.0),
  )
  @test.assert_eq(
    HasArea::unsigned_area(intersection_polygon_rect(subject, clip)),
    4.0,
  )
}
```

- Half overlap: result is half of subject area

```mbt check
///|
test "intersection_polygon_rect - half overlap" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(5.0, -5.0),
    @type.Coord::Coord(15.0, 15.0),
  )
  // Right half: 5 × 10 = 50
  @test.assert_eq(
    HasArea::unsigned_area(intersection_polygon_rect(subject, clip)),
    50.0,
  )
}
```

- Disjoint: zero area

```mbt check
///|
test "intersection_polygon_rect - disjoint inputs give zero area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  )
  let clip = @type.Rect::Rect(
    @type.Coord::Coord(10.0, 10.0),
    @type.Coord::Coord(20.0, 20.0),
  )
  @test.assert_eq(
    HasArea::unsigned_area(intersection_polygon_rect(subject, clip)),
    0.0,
  )
}
```

### `intersection_sutherland_hodgman`

- Triangle clipped by an inner triangle: result equals the inner triangle's area

```mbt check
///|
test "intersection_sutherland_hodgman - inner triangle equals clip area" {
  let subject = @type.Polygon::Polygon(
    @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (5.0, 10.0)]),
    [],
  )
  let clip = @type.Polygon::Polygon(
    @type.LineString::from_tuples([(2.0, 2.0), (8.0, 2.0), (5.0, 8.0)]),
    [],
  )
  let area = HasArea::unsigned_area(
    intersection_sutherland_hodgman(subject, clip),
  )
  // The clip triangle is entirely inside the subject — area = 0.5 * 6 * 6 = 18.
  assert_true((area - 18.0).abs() < 1.0e-9)
}
```

# euclidean.mbt

Planar Euclidean distance, squared distance, distance-to-segment, length, bearing, and destination helpers. The `HasEuclideanLength::euclidean_length` trait (in `traits.mbt`) lifts the line / line-string length functions to a uniform interface.

## Public API

- `euclidean_distance_coords`
- `euclidean_distance_points`
- `euclidean_distance_squared_coords`
- `euclidean_distance_coord_to_line`
- `euclidean_distance_point_to_line`
- `euclidean_distance_coord_to_line_string`
- `euclidean_bearing`
- `euclidean_destination`
- `HasEuclideanLength` — `euclidean_length` (impls in traits.mbt)

## Test

### `euclidean_distance_points`

- Wraps `euclidean_distance_coords` for `Point` inputs

```mbt check
///|
test "euclidean_distance_points - 3-4-5 via Point inputs" {
  @test.assert_eq(
    euclidean_distance_points(
      @type.Point::Point(0.0, 0.0),
      @type.Point::Point(3.0, 4.0),
    ),
    5.0,
  )
}
```

### Squared distance / point-to-line / coord-to-linestring / bearing

```mbt check
///|
test "euclidean - squared / point_to_line / coord_to_line_string / bearing" {
  // Squared distance avoids the sqrt: 3² + 4² = 25.
  @test.assert_eq(
    euclidean_distance_squared_coords(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(3.0, 4.0),
    ),
    25.0,
  )
  // Point → line distance: foot of perpendicular at midpoint.
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    euclidean_distance_point_to_line(@type.Point::Point(5.0, 3.0), l),
    3.0,
  )
  // Coord → linestring distance: shortest of any segment.
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])
  @test.assert_eq(
    euclidean_distance_coord_to_line_string(@type.Coord::Coord(5.0, 3.0), ls),
    3.0,
  )
  // Bearing east is 0°.
  @test.assert_eq(
    euclidean_bearing(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(1.0, 0.0),
    ),
    0.0,
  )
}
```

### `euclidean_distance_coords`

- 3-4-5 triangle: distance from origin to `(3, 4)` is 5

```mbt check
///|
test "euclidean_distance_coords - 3-4-5 triangle" {
  @test.assert_eq(
    euclidean_distance_coords(
      @type.Coord::Coord(0.0, 0.0),
      @type.Coord::Coord(3.0, 4.0),
    ),
    5.0,
  )
}
```

### `euclidean_distance_coord_to_line`

| Variable | State                          | Note                                    |  1  |  2  |
| :------- | :----------------------------- | :-------------------------------------- | :-: | :-: |
| `p`      | `Above midpoint`               | perpendicular distance                  |  ✓  |     |
| `p`      | `Off the segment past start`   | clamped to start                        |     |  ✓  |

- Point above the midpoint: perpendicular distance

```mbt check
///|
test "euclidean_distance_coord_to_line - perpendicular at midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  @test.assert_eq(
    euclidean_distance_coord_to_line(@type.Coord::Coord(5.0, 3.0), l),
    3.0,
  )
}
```

- Point past the start: clamped distance to start

```mbt check
///|
test "euclidean_distance_coord_to_line - past start clamps to start distance" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let d = euclidean_distance_coord_to_line(@type.Coord::Coord(-5.0, 3.0), l)
  let expected = (34.0 : Double).sqrt()
  assert_true((d - expected).abs() < TOLERANCE)
}
```

### `HasEuclideanLength`

#### `euclidean_length`

| Variable | State                  | Note         |  1  |  2  |
| :------- | :--------------------- | :----------- | :-: | :-: |
| `self`   | `Line` (length 5)      | 5            |  ✓  |     |
| `self`   | `LineString` (3 + 4)   | 7            |     |  ✓  |

- Line of length 5 reports 5

```mbt check
///|
test "HasEuclideanLength::euclidean_length - Line of length 5" {
  let l = @type.Line::from_tuples((0.0, 0.0), (3.0, 4.0))
  @test.assert_eq(HasEuclideanLength::euclidean_length(l), 5.0)
}
```

- LineString of total length 3 + 4 = 7

```mbt check
///|
test "HasEuclideanLength::euclidean_length - 3+4 LineString gives 7" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0), (3.0, 4.0)])
  @test.assert_eq(HasEuclideanLength::euclidean_length(ls), 7.0)
}
```

### `euclidean_destination`

- Heading east (`0°`) by distance 5 → `(5, 0)`; heading north (`90°`) by distance 5 → `(0, 5)`

```mbt check
///|
test "euclidean_destination - east and north" {
  let east = euclidean_destination(@type.Coord::Coord(0.0, 0.0), 0.0, 5.0)
  let north = euclidean_destination(@type.Coord::Coord(0.0, 0.0), 90.0, 5.0)
  // Up to floating-point round-off the results are (5, 0) and (0, 5).
  assert_true((east.x() - 5.0).abs() < TOLERANCE)
  assert_true(east.y().abs() < TOLERANCE)
  assert_true(north.x().abs() < TOLERANCE)
  assert_true((north.y() - 5.0).abs() < TOLERANCE)
}
```

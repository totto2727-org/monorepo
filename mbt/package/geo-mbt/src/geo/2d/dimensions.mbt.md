# dimensions.mbt

The `Dimensions` enum — `Empty`, `ZeroDimensional`, `OneDimensional`, `TwoDimensional` — and helpers (`rank`, `dimensions_less`) for comparing them. The `HasDimensions::dimensions` trait lifts this to whole `Geometry` values.

## Public API

- `Dimensions`
- `Dimensions::rank`
- `dimensions_less`
- `HasDimensions` — `dimensions` (impls in this file)

## Test

### `Dimensions::rank`

- The four ranks are 0, 1, 2, 3 in `Empty < ZeroDimensional < OneDimensional < TwoDimensional` order

```mbt check
///|
test "Dimensions::rank - 0..3 in natural order" {
  @test.assert_eq(Dimensions::Empty.rank(), 0)
  @test.assert_eq(Dimensions::ZeroDimensional.rank(), 1)
  @test.assert_eq(Dimensions::OneDimensional.rank(), 2)
  @test.assert_eq(Dimensions::TwoDimensional.rank(), 3)
}
```

### `dimensions_less`

- True iff the first rank is strictly smaller than the second

```mbt check
///|
test "dimensions_less - strict less by rank" {
  assert_true(dimensions_less(Dimensions::Empty, Dimensions::ZeroDimensional))
  assert_true(
    dimensions_less(Dimensions::OneDimensional, Dimensions::TwoDimensional),
  )
  assert_false(
    dimensions_less(Dimensions::TwoDimensional, Dimensions::TwoDimensional),
  )
  assert_false(
    dimensions_less(Dimensions::TwoDimensional, Dimensions::OneDimensional),
  )
}
```

### `HasDimensions`

#### `dimensions`

| Variable | State                                   | Note              |  1  |  2  |  3  |  4  |  5  |
| :------- | :-------------------------------------- | :---------------- | :-: | :-: | :-: | :-: | :-: |
| `self`   | `Point`                                 | `ZeroDimensional` |  ✓  |     |     |     |     |
| `self`   | `LineString (≥ 2 distinct coords)`      | `OneDimensional`  |     |  ✓  |     |     |     |
| `self`   | `Rect (positive width and height)`      | `TwoDimensional`  |     |     |  ✓  |     |     |
| `self`   | `Rect (zero height) / Rect (zero size)` | degenerate ranks  |     |     |     |  ✓  |     |
| `self`   | `Empty MultiPoint`                      | `Empty`           |     |     |     |     |  ✓  |

- `Point` has zero dimension

```mbt check
///|
test "HasDimensions::dimensions - Point is ZeroDimensional" {
  @test.assert_eq(
    HasDimensions::dimensions(
      @type.Geometry::Point(@type.Point::Point(0.0, 5.0)),
    ),
    Dimensions::ZeroDimensional,
  )
}
```

- `LineString` with two distinct coords has one dimension

```mbt check
///|
test "HasDimensions::dimensions - non-degenerate LineString is OneDimensional" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 5.0), (0.0, 5.0)])
  @test.assert_eq(
    HasDimensions::dimensions(@type.Geometry::LineString(ls)),
    Dimensions::OneDimensional,
  )
}
```

- `Rect` with positive width and height has two dimensions

```mbt check
///|
test "HasDimensions::dimensions - non-degenerate Rect is TwoDimensional" {
  let r = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 0.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  @test.assert_eq(
    HasDimensions::dimensions(@type.Geometry::Rect(r)),
    Dimensions::TwoDimensional,
  )
}
```

- Degenerate `Rect`s collapse to lower ranks

```mbt check
///|
test "HasDimensions::dimensions - degenerate Rect collapses to lower rank" {
  // Zero height: collapses to a horizontal segment.
  let zero_height = @type.Rect::Rect(
    @type.Coord::Coord(0.0, 10.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  @test.assert_eq(
    HasDimensions::dimensions(zero_height),
    Dimensions::OneDimensional,
  )
  // Zero width and zero height: collapses to a single point.
  let zero_size = @type.Rect::Rect(
    @type.Coord::Coord(10.0, 10.0),
    @type.Coord::Coord(10.0, 10.0),
  )
  @test.assert_eq(
    HasDimensions::dimensions(zero_size),
    Dimensions::ZeroDimensional,
  )
}
```

- Empty `MultiPoint` has dimension `Empty`

```mbt check
///|
test "HasDimensions::dimensions - empty MultiPoint is Empty" {
  let mp = @type.MultiPoint::empty()
  @test.assert_eq(
    HasDimensions::dimensions(@type.Geometry::MultiPoint(mp)),
    Dimensions::Empty,
  )
}
```

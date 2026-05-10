# multi_point.mbt

A collection of `Point`s. Provides constructors (from a `Point` array, from `(x, y)` tuples, empty), the `points` accessor, and trait impls for `HasLength` / `IsEmpty` (callable via dot syntax such as `mp.length()` because the impls live next to the struct).

## Public API

- `MultiPoint::MultiPoint`
- `MultiPoint::from_tuples`
- `MultiPoint::empty`
- `MultiPoint::points`
- `HasLength`
  - `length`
- `IsEmpty`
  - `is_empty`
- `Eq` (derived)
- `Default` (derived)

## Test

### `MultiPoint::MultiPoint`

- Simple initialization

```mbt check
///|
test "MultiPoint::MultiPoint - simple initialization" {
  let mp = MultiPoint::MultiPoint([
    Point::Point(0.0, 0.0),
    Point::Point(1.0, 1.0),
  ])
  debug_inspect(
    mp,
    content=(
      #|{ points: [{ coord: { x: 0, y: 0 } }, { coord: { x: 1, y: 1 } }] }
    ),
  )
}
```

### `MultiPoint::from_tuples`

- Builds from `(x, y)` tuple array

```mbt check
///|
test "MultiPoint::from_tuples - builds from tuple array" {
  let mp = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(
    mp,
    MultiPoint::MultiPoint([Point::Point(0.0, 0.0), Point::Point(1.0, 1.0)]),
  )
}
```

### `MultiPoint::empty`

- Equivalent to `MultiPoint::MultiPoint([])`

```mbt check
///|
test "MultiPoint::empty - equivalent to MultiPoint([])" {
  @test.assert_eq(MultiPoint::empty(), MultiPoint::MultiPoint([]))
}
```

### `MultiPoint::points`

- Returns the underlying point array

```mbt check
///|
test "MultiPoint points - returns underlying point array" {
  let mp = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(mp.points(), [Point::Point(0.0, 0.0), Point::Point(1.0, 1.0)])
}
```

### `HasLength`

#### `length`

- Returns the number of points (callable as `mp.length()` via dot syntax)

```mbt check
///|
test "MultiPoint HasLength::length - returns number of points" {
  let mp = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  @test.assert_eq(mp.length(), 2)
  @test.assert_eq(HasLength::length(mp), 2)
}
```

### `IsEmpty`

| Variable | State       | Note |  1  |  2  |
| :------- | :---------- | :--- | :-: | :-: |
| `self`   | `Non-empty` |      |  ✓  |     |
| `self`   | `Empty`     |      |     |  ✓  |

#### `is_empty`

- False when non-empty

```mbt check
///|
test "MultiPoint IsEmpty::is_empty - false when non-empty" {
  let mp = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  assert_false(mp.is_empty())
}
```

- True when empty

```mbt check
///|
test "MultiPoint IsEmpty::is_empty - true when empty" {
  assert_true(MultiPoint::empty().is_empty())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal multi-points

```mbt check
///|
test "MultiPoint Eq::op_equal - equal and unequal" {
  let a = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let b = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let c = MultiPoint::from_tuples([(0.0, 0.0), (2.0, 2.0)])
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default is empty

```mbt check
///|
test "MultiPoint Default::default - is empty" {
  let d : MultiPoint = MultiPoint::default()
  @test.assert_eq(d, MultiPoint::empty())
}
```

# multi_polygon.mbt

A collection of `Polygon`s. Provides constructors (from a `Polygon` array, empty), the `polygons` accessor, and trait impls for `HasLength` / `IsEmpty` (callable via dot syntax such as `mp.length()` because the impls live next to the struct).

## Public API

- `MultiPolygon::MultiPolygon`
- `MultiPolygon::empty`
- `MultiPolygon::polygons`
- `HasLength`
  - `length`
- `IsEmpty`
  - `is_empty`
- `Eq` (derived)
- `Default` (derived)

## Test

### `MultiPolygon::MultiPolygon`

- Simple initialization

```mbt check
///|
test "MultiPolygon::MultiPolygon - simple initialization" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let mp = MultiPolygon::MultiPolygon([Polygon::Polygon(exterior, [])])
  debug_inspect(
    mp,
    content=(
      #|{
      #|  polygons: [
      #|    {
      #|      exterior: {
      #|        coords: [
      #|          { x: 0, y: 0 },
      #|          { x: 1, y: 0 },
      #|          { x: 1, y: 1 },
      #|          { x: 0, y: 1 },
      #|          { x: 0, y: 0 },
      #|        ],
      #|      },
      #|      interiors: [],
      #|    },
      #|  ],
      #|}
    ),
  )
}
```

### `MultiPolygon::empty`

- Equivalent to `MultiPolygon::MultiPolygon([])`

```mbt check
///|
test "MultiPolygon::empty - equivalent to MultiPolygon([])" {
  @test.assert_eq(MultiPolygon::empty(), MultiPolygon::MultiPolygon([]))
}
```

### `MultiPolygon::polygons`

- Returns the underlying polygon array

```mbt check
///|
test "MultiPolygon polygons - returns underlying polygon array" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  let mp = MultiPolygon::MultiPolygon([polygon])
  @test.assert_eq(mp.polygons(), [polygon])
}
```

### `HasLength`

#### `length`

- Returns the number of polygons (callable as `mp.length()` via dot syntax)

```mbt check
///|
test "MultiPolygon HasLength::length - returns number of polygons" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let mp = MultiPolygon::MultiPolygon([Polygon::Polygon(exterior, [])])
  @test.assert_eq(mp.length(), 1)
  @test.assert_eq(HasLength::length(mp), 1)
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
test "MultiPolygon IsEmpty::is_empty - false when non-empty" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let mp = MultiPolygon::MultiPolygon([Polygon::Polygon(exterior, [])])
  assert_false(mp.is_empty())
}
```

- True when empty

```mbt check
///|
test "MultiPolygon IsEmpty::is_empty - true when empty" {
  assert_true(MultiPolygon::empty().is_empty())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal multi polygons

```mbt check
///|
test "MultiPolygon Eq::op_equal - equal and unequal" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let other_exterior = LineString::from_tuples([
    (0.0, 0.0),
    (2.0, 0.0),
    (2.0, 2.0),
    (0.0, 2.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  let other_polygon = Polygon::Polygon(other_exterior, [])
  let a = MultiPolygon::MultiPolygon([polygon])
  let b = MultiPolygon::MultiPolygon([polygon])
  let c = MultiPolygon::MultiPolygon([other_polygon])
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

### `Default` (derived)

#### `default`

- Default is empty

```mbt check
///|
test "MultiPolygon Default::default - is empty" {
  let d : MultiPolygon = MultiPolygon::default()
  @test.assert_eq(d, MultiPolygon::empty())
}
```

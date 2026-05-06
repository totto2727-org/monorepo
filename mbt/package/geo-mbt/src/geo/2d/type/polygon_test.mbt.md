# polygon.mbt

A bounded two-dimensional area defined by an `exterior` ring (`LineString`) and zero or more `interiors` (holes). The canonical constructor immutably auto-closes every input ring via `LineString::closed`. Provides accessors, ring counting, an `IsEmpty` trait impl (callable via dot syntax such as `polygon.is_empty()` because the impl lives next to the struct), and an immutable `pushed_interior` that returns a copy with one extra hole.

## Public API

- `Polygon::Polygon`
- `Polygon::exterior`
- `Polygon::interiors`
- `Polygon::num_interiors`
- `Polygon::num_rings`
- `IsEmpty`
  - `is_empty`
- `Polygon::pushed_interior`
- `Eq` (derived)

## Test

### `Polygon::Polygon`

| Variable    | State                            | Note                                       |  1  |  2  |  3  |  4  |
| :---------- | :------------------------------- | :----------------------------------------- | :-: | :-: | :-: | :-: |
| `exterior`  | `Open`                           | auto-closes (length grows by 1)            |  ✓  |     |  -  |     |
| `exterior`  | `Already closed`                 | preserved verbatim                         |     |     |  ✓  |     |
| `interiors` | `Empty`                          | basic shape                                |  ✓  |     |  ✓  |     |
| `interiors` | `Open ring`                      | auto-closes each interior                  |     |  ✓  |     |     |
| (caller)    | `Holds open exterior + interior` | constructor must not mutate input rings    |     |     |     |  ✓  |

- Simple initialization

```mbt check
///|
test "Polygon::Polygon - simple initialization" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  debug_inspect(
    polygon,
    content=(
      #|{
      #|  exterior: {
      #|    coords: [
      #|      { x: 0, y: 0 },
      #|      { x: 1, y: 0 },
      #|      { x: 1, y: 1 },
      #|      { x: 0, y: 1 },
      #|      { x: 0, y: 0 },
      #|    ],
      #|  },
      #|  interiors: [],
      #|}
    ),
  )
}
```

- Auto-closes an open exterior

```mbt check
///|
test "Polygon::Polygon - auto-closes open exterior" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  assert_true(polygon.exterior().is_closed())
  @test.assert_eq(polygon.exterior().length(), 5)
}
```

- Auto-closes each interior ring

```mbt check
///|
test "Polygon::Polygon - auto-closes each interior" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = Polygon::Polygon(exterior, [interior])
  assert_true(polygon.interiors()[0].is_closed())
}
```

- Already-closed exterior is preserved verbatim

```mbt check
///|
test "Polygon::Polygon - already-closed exterior is preserved" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  @test.assert_eq(polygon.exterior().length(), 5)
}
```

- Does not mutate caller's input `LineString`s

```mbt check
///|
test "Polygon::Polygon - does not mutate input LineStrings" {
  let user_exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let user_interior = LineString::from_tuples([
    (0.3, 0.3),
    (0.7, 0.3),
    (0.7, 0.7),
    (0.3, 0.7),
  ])
  let exterior_len_before = user_exterior.length()
  let interior_len_before = user_interior.length()
  let _ = Polygon::Polygon(user_exterior, [user_interior])
  // Caller's references remain unmutated even though the canonical
  // constructor closes both rings inside the resulting Polygon.
  @test.assert_eq(user_exterior.length(), exterior_len_before)
  @test.assert_eq(user_interior.length(), interior_len_before)
  assert_false(user_exterior.is_closed())
  assert_false(user_interior.is_closed())
}
```

### `Polygon::exterior`

- Returns the (auto-closed) exterior ring

```mbt check
///|
test "Polygon exterior - returns the closed exterior ring" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  @test.assert_eq(polygon.exterior(), exterior.closed())
}
```

### `Polygon::interiors`

- Returns the array of (auto-closed) interior rings

```mbt check
///|
test "Polygon interiors - returns array of closed interior rings" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let polygon = Polygon::Polygon(exterior, [interior])
  @test.assert_eq(polygon.interiors(), [interior.closed()])
}
```

### `Polygon::num_interiors`

| Variable | State        | Note            |  1  |  2  |
| :------- | :----------- | :-------------- | :-: | :-: |
| `self`   | `No holes`   | zero interiors  |  ✓  |     |
| `self`   | `One hole`   | one interior    |     |  ✓  |

- Zero when no holes

```mbt check
///|
test "Polygon num_interiors - zero when no holes" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  @test.assert_eq(Polygon::Polygon(exterior, []).num_interiors(), 0)
}
```

- Counts interior rings

```mbt check
///|
test "Polygon num_interiors - counts interior rings" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  @test.assert_eq(Polygon::Polygon(exterior, [interior]).num_interiors(), 1)
}
```

### `Polygon::num_rings`

- Equals `num_interiors() + 1`

```mbt check
///|
test "Polygon num_rings - equals num_interiors + 1" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let solo = Polygon::Polygon(exterior, [])
  @test.assert_eq(solo.num_rings(), solo.num_interiors() + 1)
  let interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let with_hole = solo.pushed_interior(interior)
  @test.assert_eq(with_hole.num_rings(), with_hole.num_interiors() + 1)
}
```

### `IsEmpty`

| Variable | State                | Note                          |  1  |  2  |
| :------- | :------------------- | :---------------------------- | :-: | :-: |
| `self`   | `Non-empty exterior` | false                         |  ✓  |     |
| `self`   | `Empty exterior`     | true                          |     |  ✓  |

#### `is_empty`

- False when exterior is non-empty (callable as `polygon.is_empty()` via dot syntax)

```mbt check
///|
test "Polygon IsEmpty::is_empty - false when exterior is non-empty" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  assert_false(polygon.is_empty())
}
```

- True when exterior is empty

```mbt check
///|
test "Polygon IsEmpty::is_empty - true when exterior is empty" {
  let polygon = Polygon::Polygon(LineString::empty(), [])
  assert_true(polygon.is_empty())
  assert_true(IsEmpty::is_empty(polygon))
}
```

### `Polygon::pushed_interior`

| Variable        | State                                      | Note                                         |  1  |  2  |  3  |  4  |
| :-------------- | :----------------------------------------- | :------------------------------------------- | :-: | :-: | :-: | :-: |
| `self`          | `No interiors`                             | append produces a single closed interior     |  ✓  |     |     |     |
| `self`          | `Has interiors`                            | preserved in order, new at the end           |     |     |     |  ✓  |
| `new_interior`  | `Open`                                     | auto-closed inside the result                |  ✓  |     |     |     |
| `(immutability)` | `caller's polygon`                        | original is not modified                     |     |  ✓  |     |     |
| `(immutability)` | `caller's LineString`                     | input ring is not mutated                    |     |     |  ✓  |     |

- Appends and auto-closes the new interior

```mbt check
///|
test "Polygon pushed_interior - appends and auto-closes new interior" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let original = Polygon::Polygon(exterior, [])
  let new_interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let updated = original.pushed_interior(new_interior)
  @test.assert_eq(updated.num_interiors(), 1)
  // The appended ring is auto-closed (5 coords = 4 unique + closing).
  assert_true(updated.interiors()[0].is_closed())
  @test.assert_eq(updated.interiors()[0].length(), 5)
}
```

- Original polygon is not modified

```mbt check
///|
test "Polygon pushed_interior - original polygon is not modified" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let original = Polygon::Polygon(exterior, [])
  let _ = original.pushed_interior(
    LineString::from_tuples([(3.0, 3.0), (7.0, 3.0), (7.0, 7.0), (3.0, 7.0)]),
  )
  @test.assert_eq(original.num_interiors(), 0)
}
```

- Input `LineString` is not mutated

```mbt check
///|
test "Polygon pushed_interior - input LineString is not mutated" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  let user_interior = LineString::from_tuples([
    (3.0, 3.0),
    (7.0, 3.0),
    (7.0, 7.0),
    (3.0, 7.0),
  ])
  let len_before = user_interior.length()
  let was_closed_before = user_interior.is_closed()
  let _ = polygon.pushed_interior(user_interior)
  @test.assert_eq(user_interior.length(), len_before)
  @test.assert_eq(user_interior.is_closed(), was_closed_before)
}
```

- Existing interiors are preserved in order; new ring lands at the end

```mbt check
///|
test "Polygon pushed_interior - existing interiors preserved in order" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (20.0, 0.0),
    (20.0, 20.0),
    (0.0, 20.0),
  ])
  let interior_a = LineString::from_tuples([
    (3.0, 3.0),
    (5.0, 3.0),
    (5.0, 5.0),
    (3.0, 5.0),
  ])
  let interior_b = LineString::from_tuples([
    (10.0, 10.0),
    (12.0, 10.0),
    (12.0, 12.0),
    (10.0, 12.0),
  ])
  let polygon = Polygon::Polygon(exterior, [interior_a, interior_b])
  let extra = LineString::from_tuples([
    (15.0, 15.0),
    (17.0, 15.0),
    (17.0, 17.0),
    (15.0, 17.0),
  ])
  let extended = polygon.pushed_interior(extra)
  @test.assert_eq(extended.num_interiors(), 3)
  @test.assert_eq(extended.interiors()[0], polygon.interiors()[0])
  @test.assert_eq(extended.interiors()[1], polygon.interiors()[1])
  assert_true(extended.interiors()[2].is_closed())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal polygons

```mbt check
///|
test "Polygon Eq::op_equal - equal and unequal" {
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
  let a = Polygon::Polygon(exterior, [])
  let b = Polygon::Polygon(exterior, [])
  let c = Polygon::Polygon(other_exterior, [])
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

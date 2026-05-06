# is_convex.mbt

Convexity predicate for a `LineString` (treated as a closed ring when first ≡ last). `is_convex` allows collinear consecutive triples; `is_strictly_convex` rejects them.

## Public API

- `is_convex`
- `is_strictly_convex`

## Test

### `is_convex`

| Variable | State              | Note    |  1  |  2  |
| :------- | :----------------- | :------ | :-: | :-: |
| `ls`     | `Closed square`    | true    |  ✓  |     |
| `ls`     | `Concave 'L' ring` | false   |     |  ✓  |

- Closed unit square is convex

```mbt check
///|
test "is_convex - closed unit square is convex" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(is_convex(ls))
}
```

- Concave L-shape is not convex

```mbt check
///|
test "is_convex - L-shape is not convex" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (2.0, 0.0),
    (2.0, 1.0),
    (1.0, 1.0),
    (1.0, 2.0),
    (0.0, 2.0),
    (0.0, 0.0),
  ])
  assert_false(is_convex(ls))
}
```

### `is_strictly_convex`

| Variable | State                              | Note                                |  1  |  2  |
| :------- | :--------------------------------- | :---------------------------------- | :-: | :-: |
| `ls`     | `Closed square (no collinearity)`  | true                                |  ✓  |     |
| `ls`     | `Closed ring with collinear edge`  | false (strict mode rejects it)      |     |  ✓  |

- Closed unit square is strictly convex

```mbt check
///|
test "is_strictly_convex - closed unit square is strictly convex" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  assert_true(is_strictly_convex(ls))
}
```

- Ring with three collinear coords is not strictly convex

```mbt check
///|
test "is_strictly_convex - collinear triple rejected by strict mode" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (2.0, 0.0),
    (2.0, 2.0),
    (0.0, 2.0),
    (0.0, 0.0),
  ])
  assert_true(is_convex(ls))
  assert_false(is_strictly_convex(ls))
}
```

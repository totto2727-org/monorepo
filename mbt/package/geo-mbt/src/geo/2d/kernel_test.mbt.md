# kernel.mbt

Robust orientation predicate for three coordinates `p` / `q` / `r`. Backed by `@robust.orient2d` so the result's sign is correct even when `p / q / r` are nearly collinear in floating point.

## Public API

- `Orientation`
- `orient`

## Test

### `orient`

| Variable | State                       | Note               |  1  |  2  |  3  |
| :------- | :-------------------------- | :----------------- | :-: | :-: | :-: |
| `p,q,r`  | `CCW triangle`              | `CounterClockwise` |  ✓  |     |     |
| `p,q,r`  | `CW triangle`               | `Clockwise`        |     |  ✓  |     |
| `p,q,r`  | `Collinear (on line y = x)` | `Collinear`        |     |     |  ✓  |

- CCW triangle

```mbt check
///|
test "orient - CCW triangle is CounterClockwise" {
  let p = @type.Coord::Coord(0.0, 0.0)
  let q = @type.Coord::Coord(1.0, 0.0)
  let r = @type.Coord::Coord(0.0, 1.0)
  @test.assert_eq(orient(p, q, r), Orientation::CounterClockwise)
}
```

- CW triangle

```mbt check
///|
test "orient - CW triangle is Clockwise" {
  let p = @type.Coord::Coord(0.0, 0.0)
  let q = @type.Coord::Coord(0.0, 1.0)
  let r = @type.Coord::Coord(1.0, 0.0)
  @test.assert_eq(orient(p, q, r), Orientation::Clockwise)
}
```

- Collinear

```mbt check
///|
test "orient - collinear points return Collinear" {
  let p = @type.Coord::Coord(0.0, 0.0)
  let q = @type.Coord::Coord(1.0, 1.0)
  let r = @type.Coord::Coord(2.0, 2.0)
  @test.assert_eq(orient(p, q, r), Orientation::Collinear)
}
```

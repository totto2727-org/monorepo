# rect.mbt

An axis-aligned bounded 2D rectangle defined by `min` / `max` `Coord`s. The constructor normalises the inputs so that `min.x ≤ max.x` and `min.y ≤ max.y`. Provides accessors, dimension queries (`width` / `height`), `center`, `area`, conversions to `Line` segments and `Polygon`, and `split_x` / `split_y` halves with bit-identical seams.

## Public API

- `Rect::Rect`
- `Rect::min`
- `Rect::max`
- `Rect::width`
- `Rect::height`
- `Rect::center`
- `Rect::area`
- `Rect::to_lines`
- `Rect::to_polygon`
- `Rect::split_x`
- `Rect::split_y`
- `Eq` (derived)

## Test

### `Rect::Rect`

| Variable | State                       | Note                                |  1  |  2  |
| :------- | :-------------------------- | :---------------------------------- | :-: | :-: |
| `c1`/`c2` | `min < max (canonical)`    | basic shape                         |  ✓  |     |
| `c1`/`c2` | `swapped (max, min order)` | constructor normalises to min/max   |     |  ✓  |

- Simple initialization

```mbt check
///|
test "Rect::Rect - simple initialization" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  debug_inspect(
    r,
    content=(
      #|{ min: { x: 0, y: 0 }, max: { x: 10, y: 20 } }
    ),
  )
}
```

- Normalises swapped inputs to `min` / `max`

```mbt check
///|
test "Rect::Rect - normalises swapped inputs" {
  let r = Rect::Rect(Coord::Coord(2.0, 3.0), Coord::Coord(0.0, 1.0))
  @test.assert_eq(r.min(), Coord::Coord(0.0, 1.0))
  @test.assert_eq(r.max(), Coord::Coord(2.0, 3.0))
}
```

### `Rect::min`

- Returns the min corner

```mbt check
///|
test "Rect min - returns min corner" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.min(), Coord::Coord(0.0, 0.0))
}
```

### `Rect::max`

- Returns the max corner

```mbt check
///|
test "Rect max - returns max corner" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.max(), Coord::Coord(10.0, 20.0))
}
```

### `Rect::width`

- Returns `max.x − min.x`

```mbt check
///|
test "Rect width - max.x minus min.x" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.width(), 10.0)
}
```

### `Rect::height`

- Returns `max.y − min.y`

```mbt check
///|
test "Rect height - max.y minus min.y" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.height(), 20.0)
}
```

### `Rect::center`

- Returns the centroid

```mbt check
///|
test "Rect center - returns centroid" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.center(), Coord::Coord(5.0, 10.0))
}
```

### `Rect::area`

- Returns `width * height`

```mbt check
///|
test "Rect area - width times height" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 20.0))
  @test.assert_eq(r.area(), 200.0)
}
```

### `Rect::to_lines`

- Four CCW edges starting from the `min` corner

```mbt check
///|
test "Rect to_lines - 4 edges in CCW order from min corner" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 5.0))
  let bl = Coord::Coord(0.0, 0.0)
  let br = Coord::Coord(10.0, 0.0)
  let tr = Coord::Coord(10.0, 5.0)
  let tl = Coord::Coord(0.0, 5.0)
  @test.assert_eq(r.to_lines(), [
    Line::Line(bl, br),
    Line::Line(br, tr),
    Line::Line(tr, tl),
    Line::Line(tl, bl),
  ])
}
```

### `Rect::to_polygon`

| Variable | State            | Note                                                        |  1  |  2  |
| :------- | :--------------- | :---------------------------------------------------------- | :-: | :-: |
| `self`   | `Any rectangle`  | five-coord closed exterior ring                             |  ✓  |     |
| `self`   | `vs to_lines`    | first 4 polygon coords match `to_lines` starts; ring closes |     |  ✓  |

- Closed five-coord exterior ring

```mbt check
///|
test "Rect to_polygon - closed five-coord ring" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0))
  let p = r.to_polygon()
  @test.assert_eq(p.exterior().length(), 5)
  assert_true(p.exterior().is_closed())
}
```

- Corners agree with `to_lines` starts

```mbt check
///|
test "Rect to_polygon - corners agree with to_lines starts" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(10.0, 5.0))
  let lines = r.to_lines()
  let line_starts = lines.map(Line::start)
  let polygon_coords = r.to_polygon().exterior().coords()
  // First 4 polygon coords are the to_lines starts; coord 5 closes the ring.
  @test.assert_eq(polygon_coords[0:4].to_owned(), line_starts)
  @test.assert_eq(polygon_coords[4], polygon_coords[0])
}
```

### `Rect::split_x`

| Variable | State           | Note                                                       |  1  |  2  |  3  |
| :------- | :-------------- | :--------------------------------------------------------- | :-: | :-: | :-: |
| `self`   | `Any rectangle` | equal-width halves at midpoint                             |  ✓  |     |     |
| `self`   | `Any rectangle` | shared mid-X is bit-identical on the seam                  |     |  ✓  |     |
| `self`   | `Any rectangle` | total width preserved; full height preserved on each half  |     |     |  ✓  |

- Equal-width halves at the midpoint

```mbt check
///|
test "Rect split_x - equal-width halves at midpoint" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 4.0))
  @test.assert_eq(
    r.split_x(),
    (
      Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(2.0, 4.0)),
      Rect::Rect(Coord::Coord(2.0, 0.0), Coord::Coord(4.0, 4.0)),
    ),
  )
}
```

- Shared mid-X is bit-identical on the seam

```mbt check
///|
test "Rect split_x - shared mid-X bit-identical on seam" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 4.0))
  let (left, right) = r.split_x()
  @test.assert_eq(left.max().x(), right.min().x())
}
```

- Total width preserved; full height on each half

```mbt check
///|
test "Rect split_x - total width preserved and full height on each half" {
  let r = Rect::Rect(Coord::Coord(1.0, 2.0), Coord::Coord(7.0, 5.0))
  let (left, right) = r.split_x()
  @test.assert_eq(left.width() + right.width(), r.width())
  @test.assert_eq(left.height(), r.height())
  @test.assert_eq(right.height(), r.height())
}
```

### `Rect::split_y`

| Variable | State           | Note                                                        |  1  |  2  |  3  |  4  |
| :------- | :-------------- | :---------------------------------------------------------- | :-: | :-: | :-: | :-: |
| `self`   | `Any rectangle` | equal-height halves at midpoint                             |  ✓  |     |     |     |
| `self`   | `Any rectangle` | shared mid-Y is bit-identical on the seam                   |     |  ✓  |     |     |
| `self`   | `Any rectangle` | total height preserved; full width preserved on each half   |     |     |  ✓  |     |
| `self`   | `Any rectangle` | split_x then split_y produces 4 quadrants of equal area     |     |     |     |  ✓  |

- Equal-height halves at the midpoint

```mbt check
///|
test "Rect split_y - equal-height halves at midpoint" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 4.0))
  @test.assert_eq(
    r.split_y(),
    (
      Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 2.0)),
      Rect::Rect(Coord::Coord(0.0, 2.0), Coord::Coord(4.0, 4.0)),
    ),
  )
}
```

- Shared mid-Y is bit-identical on the seam

```mbt check
///|
test "Rect split_y - shared mid-Y bit-identical on seam" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 4.0))
  let (bottom, top) = r.split_y()
  @test.assert_eq(bottom.max().y(), top.min().y())
}
```

- Total height preserved; full width on each half

```mbt check
///|
test "Rect split_y - total height preserved and full width on each half" {
  let r = Rect::Rect(Coord::Coord(1.0, 2.0), Coord::Coord(7.0, 5.0))
  let (bottom, top) = r.split_y()
  @test.assert_eq(bottom.height() + top.height(), r.height())
  @test.assert_eq(bottom.width(), r.width())
  @test.assert_eq(top.width(), r.width())
}
```

- `split_x` then `split_y` produces 4 quadrants of equal area

```mbt check
///|
test "Rect split_x then split_y - 4 quadrants of equal area" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(4.0, 4.0))
  let (left, right) = r.split_x()
  let (bottom_left, top_left) = left.split_y()
  let (bottom_right, top_right) = right.split_y()
  let total = r.area()
  @test.assert_eq(
    bottom_left.area() +
    top_left.area() +
    bottom_right.area() +
    top_right.area(),
    total,
  )
  @test.assert_eq(bottom_left.area(), total / 4.0)
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal rectangles

```mbt check
///|
test "Rect Eq::op_equal - equal and unequal" {
  let a = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0))
  let b = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0))
  let c = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(2.0, 2.0))
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
}
```

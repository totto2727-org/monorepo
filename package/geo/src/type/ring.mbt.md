# ring.mbt

Provides the `Ring` structure, representing a closed loop of coordinates, often used to define the exterior or interior boundaries of a Polygon.

## Public API

- `Ring::new`
- `RingTrait` implementation
- `LineStringTrait` implementation
- `GeometryTrait` implementation

## Test

### Ring::new

- Create new Ring

```mbt check
///|
test {
  let c1 = XY::new(0.0, 0.0)
  let c2 = XY::new(1.0, 0.0)
  let c3 = XY::new(1.0, 1.0)
  let c4 = XY::new(0.0, 0.0)
  let ring = Ring::new([c1, c2, c3, c4])
  inspect(
    ring,
    content="Ring([{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}, {x: 0, y: 0}])",
  )
}
```

### LineStringTrait

#### line_string

- Convert to LineString

```mbt check
///|
test {
  let c1 = XY::new(0.0, 0.0)
  let c2 = XY::new(1.0, 0.0)
  let c3 = XY::new(1.0, 1.0)
  let c4 = XY::new(0.0, 0.0)
  let ring = Ring::new([c1, c2, c3, c4])
  let ls = ring.line_string()
  inspect(
    ls,
    content="LineString([{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}, {x: 0, y: 0}])",
  )
}
```

### GeometryTrait

#### coord_array

- Get coordinate array

```mbt check
///|
test {
  let c1 = XY::new(0.0, 0.0)
  let c2 = XY::new(1.0, 0.0)
  let c3 = XY::new(1.0, 1.0)
  let c4 = XY::new(0.0, 0.0)
  let ring = Ring::new([c1, c2, c3, c4])
  inspect(
    ring.coord_array(),
    content="[{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}, {x: 0, y: 0}]",
  )
}
```

### RingTrait

#### ring

- Convert to Ring[XY]

```mbt check
///|
test {
  let c1 = XY::new(0.0, 0.0)
  let c2 = XY::new(1.0, 0.0)
  let c3 = XY::new(1.0, 1.0)
  let c4 = XY::new(0.0, 0.0)
  let r = Ring::new([c1, c2, c3, c4])
  inspect(
    r.ring(),
    content="Ring([{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}, {x: 0, y: 0}])",
  )
}
```

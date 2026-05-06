# `translate.mbt` — shift a geometry by a fixed offset

## Goal

Move a geometry by `(dx, dy)`. Every coord `(x, y)` becomes `(x + dx, y + dy)`. The shape and orientation stay the same; only the position changes.

## API surface

```moonbit nocheck
pub fn translate_point(p : Point, dx : Double, dy : Double) -> Point
pub fn translate_polygon(p : Polygon, dx : Double, dy : Double) -> Polygon
pub fn translate_geometry(g : Geometry, dx : Double, dy : Double) -> Geometry
```

## How it works

Translate is a special case of affine transformation:

```
result = AffineTransform::translate_xy(dx, dy).apply(coord)
```

But in practice, the per-coord operation is just an addition:

```
new_x = x + dx
new_y = y + dy
```

The implementation is a one-line wrapper around `map_coords_in_*` with the closure `fn(c) { Coord(c.x() + dx, c.y() + dy) }`.

## Examples

```moonbit nocheck
let p = @type.Point::Point(3.0, 4.0)
@lib2d.translate_point(p, 10.0, -2.0)        // Point(13, 2)

let polygon = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]),
  [],
)
let shifted = @lib2d.translate_polygon(polygon, 10.0, 5.0)
// Each coord shifted by (10, 5):
// exterior: [(10, 5), (11, 5), (11, 6), (10, 6), (10, 5)]
```

Tests in `affine_transform_test.mbt`:

- `translate_polygon shifts all coords`

Property test (`property_test.mbt`):

- `property: translate is invertible` — `translate(g, dx, dy)` followed by `translate(g', -dx, -dy)` returns coords equal to the original (up to floating-point).

## Properties

- **Invariants preserved**: shape, area, perimeter, orientation (winding), convexity.
- **Distances preserved**: distance between any two points is the same before and after translate.
- **Bounding rect**: shifts by `(dx, dy)` (i.e. its `min` and `max` both shift).

## Edge cases

- **`dx == 0, dy == 0`**: identity. Returns a fresh value structurally identical to the input (a copy, not the same `Geometry` reference).
- **Empty geometries**: untouched.
- **Non-finite offsets** (NaN, Inf): propagate to every coord. Use `validation.mbt` upstream if your offsets may be dirty.

## Performance

`O(n)` where `n` is the total coord count. One add per coord per axis, no allocation beyond the output array.

## Related

- `affine_transform.mbt` — for combining translate with rotate / scale / skew in a single pass.
- `rotate.mbt`, `scale.mbt`, `skew.mbt` — sister operations.
- `map_coords.mbt` — the underlying functor.

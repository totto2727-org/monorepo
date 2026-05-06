# `scale.mbt` — stretch / shrink a geometry around a pivot

## Goal

Scale a geometry by uniform or per-axis factors around a pivot point:

- `(x, y) ↦ (pivot.x + sx · (x − pivot.x), pivot.y + sy · (y − pivot.y))`

`sx > 1` enlarges along `x`; `sx < 1` shrinks; `sx < 0` flips the geometry across the pivot's vertical line. Same for `y` with `sy`.

## API surface

```moonbit nocheck
pub fn scale_geometry(g : Geometry, factor : Double) -> Geometry
pub fn scale_geometry_around(g : Geometry, sx : Double, sy : Double, pivot : Coord) -> Geometry
```

| Function                       | Pivot                       | Factor      |
| ------------------------------ | --------------------------- | ----------- |
| `scale_geometry`               | The geometry's centroid      | Uniform `factor` for both axes |
| `scale_geometry_around`        | User-provided                | Per-axis `(sx, sy)` |

## How it works

Scaling around a pivot is the same three-step pattern as rotate:

```
T = translate(+pivot)  ∘  scale_origin(sx, sy)  ∘  translate(-pivot)
```

The middle "scale around the origin" step is the easy case:

```
new_x = sx · x
new_y = sy · y
```

`scale_geometry(g, factor)` is a thin wrapper that:

1. Computes the centroid (`centroid_geometry(g)`).
2. Calls `scale_geometry_around(g, factor, factor, centroid)`.

## Examples

```moonbit nocheck
let square = @type.Geometry::Polygon(@type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)]),
  [],
))

// Scale 2x around origin
@lib2d.scale_geometry_around(square, 2.0, 2.0, @type.Coord(0.0, 0.0))
// Result: square corners at (0, 0), (4, 0), (4, 4), (0, 4)

// Scale 0.5x around centroid (1, 1) — shrinks in place
@lib2d.scale_geometry(square, 0.5)
// Result: corners at (0.5, 0.5), (1.5, 0.5), (1.5, 1.5), (0.5, 1.5)

// Negative factor: flip across pivot
@lib2d.scale_geometry_around(square, -1.0, 1.0, @type.Coord(0.0, 0.0))
// Result: x-flipped square at (0, 0), (-2, 0), (-2, 2), (0, 2)
```

Tests in `affine_transform_test.mbt`:

- `AffineTransform::scale_xy`
- `scale_geometry_around: 2x around origin`

Property test (`property_test.mbt`):

- `property: scale preserves shape (area scales by factor squared)` — for a uniform scale by `f`, area is multiplied by `f²`.

## Properties

- **Shape NOT preserved** when `sx ≠ sy` (non-uniform scale stretches the geometry, distorting angles).
- **Shape preserved up to size** when `sx == sy` (similarity transformation).
- **Area** scales by `|sx · sy|`. For uniform scale `f`, that's `f²`.
- **Perimeter / lengths** scale by `|sx|` (along x) and `|sy|` (along y) — non-trivial for non-uniform scales because each segment's length depends on its angle.
- **Winding** flips when exactly one of `sx, sy` is negative (an odd number of axis flips). Two negative factors keep the winding (180° rotation).

## Edge cases

- **`factor = 0`**: collapses the geometry to a single coord (the pivot). The result is structurally still a polygon / line string but with all coords identical — usually invalid for downstream algorithms. Validate before relying on it.
- **`factor = 1`**: identity (returns a structurally-equal copy).
- **Negative factor**: flip. Combine with another flip on the other axis to get a 180° rotation around the pivot.

## Performance

`O(n)` — one multiply-and-add per coord per axis. The pivot subtraction and reconstruction are folded into the affine matrix.

## Related

- `affine_transform.mbt` — for composing scale with translate / rotate / skew.
- `translate.mbt`, `rotate.mbt`, `skew.mbt` — sister operations.
- `centroid.mbt` — computes the pivot for `scale_geometry`.

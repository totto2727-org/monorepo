# `rotate.mbt` — rotate a geometry by an angle

## Goal

Rotate a geometry by `θ` radians around a pivot point. The pivot can be:

- a user-specified `Coord`,
- the geometry's **centroid** (a "spin in place" rotation), via the `_around_centroid` variant.

A positive `θ` rotates **counter-clockwise** (math convention). For clockwise rotation, pass a negative angle.

## API surface

```moonbit nocheck
pub fn rotate_geometry_around(g : Geometry, angle_radians : Double, pivot : Coord) -> Geometry
pub fn rotate_geometry_around_centroid(g : Geometry, angle_radians : Double) -> Geometry
```

## How it works

Rotation around an arbitrary pivot is a composition of three transformations:

```
1. translate so the pivot is at the origin     (translate by -pivot)
2. rotate around the origin by θ                (the easy case)
3. translate back                                (translate by +pivot)
```

In matrix form:

```
T = translate(+pivot)  ∘  rotate_origin(θ)  ∘  translate(-pivot)
```

Once `T` is built, every coord is transformed by one matrix-vector product — `O(1)` per coord.

The "rotate around the origin" step itself uses the standard rotation matrix:

```
| cos θ   −sin θ |   | x |     | x · cos θ − y · sin θ |
|              | · |   |  =  |                       |
| sin θ    cos θ |   | y |     | x · sin θ + y · cos θ |
```

For `_around_centroid`, the pivot is computed first via `centroid_geometry(g)` (returning `None` for empty / degenerate geometries — in which case rotate returns the input unchanged) and then the same pivoted-rotate runs.

## Examples

```moonbit nocheck
///|
let unit_square = @type.Geometry::Polygon(
  @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
    ]),
    [],
  ),
)

// Rotate 90° CCW around origin

///|
let rotated = @lib2d.rotate_geometry_around(
  unit_square,
  @math.pi / 2.0,
  @type.Coord(0.0, 0.0),
)
// Square is now in the second quadrant: corners (-1, 0), (-1, 1), (0, 1), (0, 0)

// Rotate 180° around its own centroid (= (0.5, 0.5)) — square stays in place
//   because a square is rotationally symmetric every 90°.

///|
let spun = @lib2d.rotate_geometry_around_centroid(unit_square, @math.pi)
// `spun`'s vertex order is reversed but the shape is at the same coords.
```

Tests in `affine_transform_test.mbt`:

- `AffineTransform::rotate_origin 90 degrees`
- `rotate_geometry_around: pivot at origin, square 180`

## Properties

- **Shape preserved**: distances and angles within the geometry stay the same. Rotation is a *rigid motion*.
- **Area preserved**.
- **Winding preserved**: a CCW polygon stays CCW.
- **Bounding rect**: generally **does not** preserve. The bbox after rotation is at least as large as the original (and exactly as large iff θ is a multiple of 90°).

## Edge cases

- **`θ = 0`**: identity (small floating-point noise from `sin 0` / `cos 0` is negligible).
- **Pivot at infinity / NaN**: propagates non-finite values throughout.
- **Empty geometry**: returned unchanged.
- **Centroid = `None`** (zero-area / zero-length input): `_around_centroid` returns the input unchanged.

## Performance

`O(n)` per geometry — one trigonometric pair (`sin θ`, `cos θ`) computed once for the matrix, then `O(1)` per coord. The trigonometric work is amortised across all coords.

## Related

- `affine_transform.mbt` — when you want to compose rotate with translate / scale / skew in a single pass.
- `translate.mbt`, `scale.mbt`, `skew.mbt` — sister operations.
- `centroid.mbt` — computes the pivot for `_around_centroid`.

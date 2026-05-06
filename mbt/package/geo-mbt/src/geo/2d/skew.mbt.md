# `skew.mbt` — shear a geometry along x and / or y

## Goal

Apply a **shear** transformation to a geometry. A shear tilts the shape so that horizontal lines slope (skew_x) or vertical lines slant (skew_y), without rotating.

## API surface

```moonbit nocheck
pub fn skew_geometry(g : Geometry, skew_x_radians : Double, skew_y_radians : Double) -> Geometry
pub fn skew_geometry_around(g : Geometry, skew_x_radians : Double, skew_y_radians : Double, pivot : Coord) -> Geometry
```

`skew_geometry` skews around the centroid; `skew_geometry_around` lets you specify the pivot.

The angles are in **radians**. A skew angle of 45° (`π/4`) along x means horizontal lines tilt to make a 45° slope.

## How it works

In matrix form a shear around the origin is:

```
| 1   tan α   0 |
| tan β   1   0 |
| 0       0   1 |
```

`α` is the **x-skew** angle (how much horizontal lines tilt up to the right), `β` is the **y-skew** angle.

For per-coord arithmetic:

```
new_x = x  +  tan(α) · y
new_y = y  +  tan(β) · x
```

For a pivot other than the origin, sandwich the shear between translates (the same pattern as rotate / scale):

```
T = translate(+pivot)  ∘  skew_origin(α, β)  ∘  translate(-pivot)
```

`skew_geometry` first computes the centroid, then calls `skew_geometry_around` with that pivot.

## What skew does visually

```
α = 45°,  β = 0           α = 0,    β = 45°          α = 30°,  β = 30°
horizontal slope          vertical slant             both

before:                   before:                    before:
┌────────┐                ┌────────┐                 ┌────────┐
│        │                │        │                 │        │
│        │                │        │                 │        │
└────────┘                └────────┘                 └────────┘

after:                    after:                     after:
┌──────────┐              ┌────────┐                 ┌──────────┐
\          \              \         \                \          \
 \          \              \         \                \          \
  └──────────┘              └────────┘                 └──────────┘
```

A pure x-skew turns rectangles into parallelograms with horizontal top/bottom edges; a pure y-skew tilts the vertical edges.

## Examples

```moonbit nocheck
// Shear x by 45°
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

///|
let sheared = @lib2d.skew_geometry(unit_square, @math.pi / 4.0, 0.0)
//   bottom corners stay at y = 0 (because tan(45°) · 0 = 0)
//   top corners shift right by tan(45°) · 1 = 1
//   resulting parallelogram: (0, 0), (1, 0), (2, 1), (1, 1)
```

Tests in `affine_transform_test.mbt`:

- `skew_geometry: shear x by 45 deg`

## Properties

- **Areas preserved**. A shear has determinant `1 + tan(α) · tan(β)`. For pure-x or pure-y skew (β = 0 or α = 0), determinant = 1, so area is preserved exactly. For mixed shears the area changes by that determinant factor.
- **Lines stay lines**, but parallel lines stay parallel. (This is one of the defining properties of affine transformations.)
- **Angles between lines change** in general. Shear is not a similarity transformation.
- **Winding preserved** when the determinant is positive (almost always for sensible angles).

## Edge cases

- **`α = β = 0`**: identity.
- **`α = π/2`** or any odd multiple: `tan(α) = ∞`. The transformation collapses every horizontal line onto a single vertical line — degenerate. The port doesn't guard against this; callers should clamp angles away from `π/2`.

## Performance

`O(n)` — one `tan` computation per axis up front, then one multiply-and-add per coord per axis.

## Related

- `affine_transform.mbt` — composing skew with translate / scale / rotate.
- `translate.mbt`, `rotate.mbt`, `scale.mbt` — sister operations.
- `centroid.mbt` — computes the pivot for `skew_geometry`.

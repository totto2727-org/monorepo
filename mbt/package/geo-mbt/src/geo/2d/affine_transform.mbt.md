# `affine_transform.mbt` — composable 2D affine transformations

## Goal

Provide an **`AffineTransform`** value type that captures any 2D linear-plus-translation transformation as a single object — translate, scale, rotate, skew, or any composition of these — and applies it to coordinates in `O(1)` per coord.

The whole transformation is stored as 6 numbers (a 2×3 matrix in homogeneous coords). Composing two transformations `(M ∘ N)` produces another `AffineTransform` so chains stay flat instead of recursive.

## API surface

```moonbit nocheck
pub struct AffineTransform {
  a    : Double  // x-scale     |a  b  xoff|
  b    : Double  // x-skew      |        |
  xoff : Double  // x-translate
  d    : Double  // y-skew      |d  e  yoff|
  e    : Double  // y-scale     |        |
  yoff : Double  // y-translate (third row implicitly  |0 0 1|)
}

pub fn AffineTransform::new(a, b, xoff, d, e, yoff) -> Self
pub fn AffineTransform::identity() -> Self        // identity transform
pub fn AffineTransform::translate_xy(dx, dy) -> Self
pub fn AffineTransform::scale_xy(sx, sy) -> Self
pub fn AffineTransform::rotate_origin(angle_radians) -> Self
pub fn AffineTransform::skew_origin(skew_x_radians, skew_y_radians) -> Self
pub fn AffineTransform::compose(self, other) -> Self
pub fn AffineTransform::apply(self, c : Coord) -> Coord
```

## What an affine transformation is

In 2D, an **affine transformation** maps any coord `(x, y)` to a new coord via:

```
x' = a · x  +  b · y  +  xoff
y' = d · x  +  e · y  +  yoff
```

The 4 numbers `a, b, d, e` form the **linear** part (rotation + scale + skew); the 2 numbers `xoff, yoff` are the **translation** part. Every operation in the Affine family — translate, scale, rotate, skew — is just a particular pattern of these 6 numbers.

In matrix form (homogeneous coords):

```
| x' |     | a  b  xoff |   | x |
| y' |  =  | d  e  yoff | · | y |
| 1  |     | 0  0   1   |   | 1 |
```

The implementation stores only the top 6 numbers (the bottom row `[0 0 1]` is implied).

## Pre-built transformations

| Constructor            | Matrix                            | Effect                                   |
| ---------------------- | --------------------------------- | ---------------------------------------- |
| `identity()`           | `[1 0 0; 0 1 0]`                  | Coord ↦ coord (no change)                |
| `translate_xy(dx, dy)` | `[1 0 dx; 0 1 dy]`                | Shift everything by `(dx, dy)`           |
| `scale_xy(sx, sy)`     | `[sx 0 0; 0 sy 0]`                | Stretch / shrink. Negative values flip   |
| `rotate_origin(θ)`     | `[cos θ −sin θ 0; sin θ cos θ 0]` | Rotate `θ` radians CCW around the origin |
| `skew_origin(α, β)`    | `[1 tan α 0; tan β 1 0]`          | Shear along x by α, along y by β         |

## Composing transformations

`compose(self, other)` produces a new transform that applies `other` first, then `self`. Matrix-wise:

```
self ∘ other  =  self.matrix · other.matrix
```

Reading order:

```moonbit nocheck
///|
let t = AffineTransform::translate_xy(10.0, 0.0).compose(
  AffineTransform::rotate_origin(@math.PI / 2.0),
)
// `t` first rotates the input 90° CCW, then translates +10 along x
//
// Equivalent to:
//   for each coord c:
//     rotated = rotate_origin(π/2).apply(c)
//     final   = translate_xy(10, 0).apply(rotated)
```

The composition order is **right-to-left** (innermost first), matching the matrix-multiplication convention. This is the same as in WebGL / SVG / OpenGL transformation stacks.

## Applying to a single coord

`apply(self, c)` does the matrix-vector product:

```
result.x = self.a · c.x  +  self.b · c.y  +  self.xoff
result.y = self.d · c.x  +  self.e · c.y  +  self.yoff
```

`O(1)` per coord. The bulk forms (`affine_transform_geometry`, `affine_transform_polygon`, etc.) walk the geometry's coords with `apply` via `map_coords_in_*` — a single composed transform is built once, then applied to every vertex, regardless of how complex the chain was.

## Examples

```moonbit nocheck
// Build a "rotate around centre then translate" transform:
let centre = @type.Coord(50.0, 50.0)
let t =
  AffineTransform::translate_xy(centre.x(), centre.y())
    .compose(AffineTransform::rotate_origin(@math.PI / 4.0))    // 45°
    .compose(AffineTransform::translate_xy(-centre.x(), -centre.y()))

// Apply to a polygon:
@lib2d.affine_transform_polygon(my_polygon, t)
//   rotates `my_polygon` 45° around (50, 50)
```

Tests in `affine_transform_test.mbt`:

- `AffineTransform::identity`
- `AffineTransform::translate_xy`
- `AffineTransform::scale_xy`
- `AffineTransform::rotate_origin 90 degrees`
- `AffineTransform composition: translate then scale`

Plus the bench `bench: affine transform translate+rotate compose`.

## Why store the matrix instead of recomputing each step

The alternative (store a list of `(operation, parameters)` and replay them per coord) is `O(k)` per coord (k = chain depth). The matrix form is `O(1)` per coord regardless of how the transform was built. For a transform of any complexity applied to many coords, the matrix wins decisively.

## Composition rules / properties

- **Identity is the unit**: `identity ∘ T == T == T ∘ identity`.
- **Associative**: `(A ∘ B) ∘ C == A ∘ (B ∘ C)`.
- **NOT commutative** in general: `translate(10) ∘ rotate(π/2) ≠ rotate(π/2) ∘ translate(10)`. Order matters!

## What's missing

The port doesn't currently expose:

- `inverse()` — for computing the inverse transform (matrix inverse). Useful when "undoing" a transform applied earlier.
- `compose_many` — variadic compose (the chain pattern with `.compose()` works fine).
- `is_identity()` / `scaled` / `translated` / `rotated` / `skewed` (alternative builder-style API surface from upstream `geo`).

These are post-scope (⏳ in `api-correspondence.md` §2.2 row `affine_ops::AffineTransform::*`).

## Related

- `translate.mbt`, `rotate.mbt`, `scale.mbt`, `skew.mbt` — convenience wrappers that build the right `AffineTransform` and apply it via `affine_transform_*`.
- `map_coords.mbt` — the underlying functor that walks every coord and applies the per-coord function.

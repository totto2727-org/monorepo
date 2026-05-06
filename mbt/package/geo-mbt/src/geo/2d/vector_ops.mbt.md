# `vector_ops.mbt` — 2D vector primitives on `Coord`

## Goal

Treat `Coord` as a 2D vector and provide the small handful of operations that every geometric algorithm wants: magnitude, normalisation, dot product, the 2D wedge / cross product, and the two 90° rotations.

These are the building blocks for distance, projection, bearing, orientation tests, and so on. They are intentionally **not** trait-shaped — they're free functions on `Coord` so they're cheap to call inline.

## API surface

| Function               | Returns  | Description                                                                  |
| ---------------------- | -------- | ---------------------------------------------------------------------------- |
| `magnitude(c)`         | `Double` | `sqrt(x² + y²)` — the Euclidean length / norm of `c`                         |
| `magnitude_squared(c)` | `Double` | `x² + y²` — skips the `sqrt`. Use this when you only need to compare lengths |
| `dot_product(a, b)`    | `Double` | `a.x*b.x + a.y*b.y`                                                          |
| `wedge_product(a, b)`  | `Double` | `a.x*b.y − a.y*b.x` — the 2D cross product (a scalar in 2D)                  |
| `try_normalize(c)`     | `Coord?` | `c / magnitude(c)`. `None` when `magnitude` is 0 or non-finite               |
| `is_finite(c)`         | `Bool`   | Both `x` and `y` are finite (rejects `NaN` / `±Inf`)                         |
| `left(c)`              | `Coord`  | 90° CCW rotation: `Coord(-c.y, c.x)`                                         |
| `right(c)`             | `Coord`  | 90° CW rotation: `Coord(c.y, -c.x)`                                          |

`Coord::dot` and `Coord::cross` are method aliases of `dot_product` and `wedge_product` respectively, sitting on the type itself for ergonomic `.dot()` / `.cross()` chaining.

## Why "wedge product" not "cross product"

In 3D, the cross product `a × b` returns a vector perpendicular to both inputs. In 2D you only have one degree of freedom for that perpendicular direction — by convention the z-component of the embedded 3D cross — so the 2D analogue is a _scalar_: `a.x*b.y − a.y*b.x`.

This scalar is also called the **wedge product** (`a ∧ b`) or the **2D cross product**. Its sign and magnitude carry geometric meaning:

- **Sign** ⇒ orientation. Positive ⇒ `b` is CCW from `a`; negative ⇒ CW; zero ⇒ collinear.
- **|wedge|** ⇒ the area of the parallelogram spanned by `a` and `b`. (Half of that is the triangle area, which is exactly what `signed_area_of_triangle` computes.)

## `try_normalize` semantics

```
try_normalize(Coord(0, 0))                → None      // zero vector has no direction
try_normalize(Coord(NaN, 0))              → None      // not finite
try_normalize(Coord(3, 4))                → Some Coord(0.6, 0.8)   // length-1 unit vector
```

The port returns `None` rather than dividing by zero / propagating `NaN`. Algorithms that need a unit vector should pattern-match on the result and decide what to do for the degenerate case.

## `left` / `right` — 90° turns

```
v = Coord(3, 1)         right(v) = Coord(1, -3)         (rotated 90° clockwise)
                                                          ↓
                                                       Coord(3, 1)
                            left(v) = Coord(-1, 3)         ↑
                                                       Coord(-1, 3)
```

These are useful for computing **normals** to a line: given a direction vector `d`, `left(d)` and `right(d)` are the two unit-perpendicular candidates (after dividing by `magnitude(d)`).

## Examples

```moonbit nocheck
let v = @type.Coord(3.0, 4.0)
let m = @lib2d.magnitude(v)            // 5.0
let unit = @lib2d.try_normalize(v).unwrap()
// unit == Coord(0.6, 0.8)

let a = @type.Coord(1.0, 0.0)
let b = @type.Coord(0.0, 1.0)
@lib2d.dot_product(a, b)               // 0.0   (perpendicular)
@lib2d.wedge_product(a, b)             // 1.0   (CCW unit area)

@lib2d.left(@type.Coord(1.0, 0.0))     // Coord(0, 1)
@lib2d.right(@type.Coord(1.0, 0.0))    // Coord(0, -1)
```

Tests live in `vector_ops_test.mbt`:

- `magnitude`, `dot_product / wedge_product`
- `try_normalize`, `try_normalize zero vector returns None`
- `is_finite`, `left / right rotation`

## Performance

All of these are constant-time, allocation-free, and trivially inlinable.

## Notes for upstream parity

In Rust upstream `geo`, this is the `Vector2DOps` trait with the same set of operations. The port flattens it into free functions because MoonBit doesn't have the same blanket-impl pattern, and because every algorithm in the port already takes `Coord` directly — adding a trait dispatch wouldn't earn its complexity here.

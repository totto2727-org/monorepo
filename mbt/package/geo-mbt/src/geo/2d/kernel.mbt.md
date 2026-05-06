# `kernel.mbt` — orientation predicate (`orient2d`) wrapper

## Goal

Decide whether three points `(p, q, r)` lie on a line **CCW**, **CW**, or **collinearly**. This single primitive is the foundation of almost every non-trivial geometric algorithm: convex hull, point-in-polygon, line-intersection, sweep lines, and triangulation all rely on it.

The port wraps the robust predicate `@robust.orient2d` from `src/robust/` and presents it under two names:

- `orient(p, q, r) -> Orientation` — returns the enum
- `signed_area_of_triangle_robust(a, b, c) -> Double` — returns the underlying numeric value (`2 × signed area` of the triangle)

Both go through the same code path; only the post-processing differs.

## API surface

```moonbit nocheck
pub(all) enum Orientation {
  CounterClockwise   // p, q, r turn left
  Clockwise          // p, q, r turn right
  Collinear          // p, q, r are on the same straight line
}

pub fn orient(p : Coord, q : Coord, r : Coord) -> Orientation
pub fn signed_area_of_triangle_robust(a : Coord, b : Coord, c : Coord) -> Double
```

## Why robust matters

The mathematically pure formula is

```
det = (q.x − p.x) · (r.y − q.y)  −  (q.y − p.y) · (r.x − q.x)
```

The sign of `det` tells you the orientation. The problem is that `det` is the difference of two products of differences — when `(p, q, r)` are *almost* collinear, `det` is the difference of two very-close-to-equal numbers, and IEEE-754 double-precision rounding can flip its sign. A flipped sign means an algorithm that depends on it (e.g. convex hull) can output a structurally wrong result.

`@robust.orient2d` solves this by using **Shewchuk's adaptive precision arithmetic** — it computes the determinant in extended precision only when the result is too close to zero to trust the simple formula. The result has the **mathematically correct sign** in all cases, with negligible cost in the common (non-collinear) case.

This file is the public-facing wrapper; the actual numerical work lives in `src/robust/orient2d.mbt`.

## Step-by-step (`orient`)

```
input: three Coord points  p, q, r

1. det = @robust.orient2d(p, q, r)    // robust signed area × 2
2. match det.sign:
     > 0   →  CounterClockwise
     < 0   →  Clockwise
     == 0  →  Collinear
```

That is the entire function. The interesting work is hidden inside `@robust.orient2d`.

## Geometric reading of the determinant

The formula is `2 × signed_area(triangle p-q-r)`:

- **Positive** ⇒ the three points wrap CCW (left-turn at `q`).
- **Negative** ⇒ they wrap CW (right-turn at `q`).
- **Zero** ⇒ exactly collinear.

You can also read it as: `det > 0` iff `r` lies on the **left side** of the directed line `p → q`.

```
       r
       •
      ╱
     ╱     orient(p, q, r) = CounterClockwise
    ╱      (left turn at q)
   ╱
  q ──────── p

       q ──────── p
        ╲
         ╲        orient(p, q, r) = Clockwise
          ╲       (right turn at q)
           ╲
            •
            r
```

## Examples

```moonbit nocheck
let p = @type.Coord(0.0, 0.0)
let q = @type.Coord(1.0, 0.0)
let r_ccw = @type.Coord(1.0, 1.0)
let r_cw  = @type.Coord(1.0, -1.0)
let r_col = @type.Coord(2.0, 0.0)

@lib2d.orient(p, q, r_ccw)   // CounterClockwise
@lib2d.orient(p, q, r_cw)    // Clockwise
@lib2d.orient(p, q, r_col)   // Collinear
```

Tests in `kernel_test.mbt`:

- `orient: counter-clockwise triangle`
- `orient: clockwise triangle`
- `orient: collinear`
- `signed_area_of_triangle_robust`

The robust difference vs. naive `cross_prod` is exercised by `kernel_bench_test.mbt`'s `bench: orient2d (robust)` plus the `robust/orient2d_test.mbt` tests `orient2d high-precision tiny inputs` (which constructs inputs that would flip the sign under naive `f64` arithmetic).

## Where this is used

- `convex_hull.mbt` — Andrew's monotone chain uses `orient` to decide which points to keep on the hull
- `is_convex.mbt` — checks that `orient` returns the same sign at every triple along a ring
- `winding_order.mbt` — relies on the sign of `signed_area_of_triangle_robust` summed over a ring
- `line_intersection.mbt` — uses `orient` to detect whether two segments cross
- `coordinate_position.mbt` (and downstream `contains` / `intersects`) — uses `orient` for left/right tests during ray casting

If you're writing a new geometric algorithm in this port, **always** reach for `orient` rather than computing a determinant by hand. The cost is the same in the easy case, and you avoid a whole class of correctness bugs.

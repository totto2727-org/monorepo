# `robust/incircle.mbt` — robust "is point inside circumcircle" predicate

## Goal

Decide whether a point `d` lies **inside, on, or outside** the **circumcircle** of triangle `(a, b, c)`. Returns the sign of a determinant whose magnitude is unimportant.

This is the second pillar of robust 2D computational geometry (the first being `orient2d.mbt`). It's the foundational primitive for **Delaunay triangulation**: a triangulation is Delaunay iff for every triangle `T`, no other vertex lies inside `T`'s circumcircle.

## Why this primitive matters

Delaunay triangulation maximises the minimum angle across all triangles — it produces the "fattest" triangles possible for a given point set. The way to check if a triangulation is Delaunay is the in-circle test: for each triangle `(a, b, c)` and each other point `d`, `incircle(a, b, c, d) ≤ 0`.

Many other algorithms also need this primitive:

- Triangle subdivision (Bowyer–Watson, Lawson edge-flip).
- Voronoi diagram construction (the dual of Delaunay).
- Mesh quality improvement.

The port doesn't currently implement Delaunay (out of scope), but the `incircle` primitive is provided so that future scope work can build on top.

## API surface

```moonbit nocheck
pub fn incircle(pa : Coord, pb : Coord, pc : Coord, pd : Coord) -> Double
```

Convention: `pa, pb, pc` should be in **counter-clockwise** order. Then the return value's sign is:

- `> 0` ⇒ `pd` is **inside** the circumcircle.
- `< 0` ⇒ `pd` is **outside**.
- `= 0` ⇒ `pd` is **on** the circumcircle.

If the input is in CW order, the signs are flipped — many implementations call `orient2d` first to normalise the order.

## Algorithm — same Shewchuk scheme as `orient2d`

The mathematically pure formula is a 4×4 determinant:

```
                | ax − dx   ay − dy   (ax − dx)² + (ay − dy)² |
incircle  =  −  | bx − dx   by − dy   (bx − dx)² + (by − dy)² |
                | cx − dx   cy − dy   (cx − dx)² + (cy − dy)² |
```

Each term in the third column is the squared distance from one of `pa, pb, pc` to `pd`. Geometrically, the determinant projects all four points to a paraboloid and asks whether the lifted `d` is above or below the plane through the lifted `a, b, c`.

The sign is the same problem as `orient2d`: a difference of large products that can lose its sign under naive `f64` arithmetic. Shewchuk's adaptive precision strategy applies:

```
Stage 1 — fast non-adaptive:
  Compute the determinant directly with f64 multiplications.
  Compare |result| against a precomputed error bound (ICCERRBOUND_A/B/C).
  If |result| exceeds the bound: trust the sign and return.

Stage 2 — adaptive refinement:
  Use floating-point expansions to compute the determinant exactly.
  Refine until the sign is certain.
```

The same `two_sum`, `two_product`, `scale_expansion_zeroelim`, etc. primitives from `expansion.mbt` power the refinement.

## Examples

```moonbit nocheck
// Triangle in CCW order with vertices on a unit circle
let a = @type.Coord(1.0, 0.0)
let b = @type.Coord(-0.5, 0.866)    // 120° on unit circle
let c = @type.Coord(-0.5, -0.866)   // 240° on unit circle

// Origin: inside the unit circle (the circumcircle here)
@robust.incircle(a, b, c, @type.Coord(0.0, 0.0))    // > 0

// (2, 0): outside
@robust.incircle(a, b, c, @type.Coord(2.0, 0.0))    // < 0

// On the circle: result = 0 (or near it within Stage 2's exact precision)
@robust.incircle(a, b, c, @type.Coord(1.0, 0.0))    // == 0  (exactly the same as `a`)
```

Tests in `robust/incircle_test.mbt`:

- `incircle basic — point inside`
- `incircle basic — point outside`

## Edge cases

- **Degenerate triangle** (collinear `a, b, c`): the circumcircle is undefined (a "line at infinity"). The determinant degenerates and the sign may be misleading. Pre-flight with `orient2d` to confirm `a, b, c` are non-collinear.
- **CW input order**: result sign is flipped from the CCW convention.
- **Coincident points** (e.g. `pd == pa`): result is `0` (the point is on the circle by definition — it's a vertex).

## Performance

Same scheme as `orient2d`:

- **Stage 1**: ~10 f64 ops, ~15 ns.
- **Stage 2**: up to ~thousands of ops in the adversarial case, ~hundreds of ns.

The port doesn't have a benchmark for `incircle` yet (no callers in the current scope); benchmarks would land alongside the future Delaunay implementation.

## Related

- `orient2d.mbt` — sibling robust predicate. Often called as a pre-check.
- `expansion.mbt` — the floating-point expansion primitives that power Stage 2 refinement.
- The corresponding upstream Rust implementation in the `robust` crate ports the same Shewchuk paper.

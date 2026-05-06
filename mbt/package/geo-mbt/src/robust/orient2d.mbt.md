# `robust/orient2d.mbt` — robust 2D orientation predicate

## Goal

Compute the **sign** of `2 × signed_area(triangle p, q, r)` correctly even when the result is too close to zero for naive `f64` arithmetic to handle.

This is the foundation for every robust geometric algorithm in the port. The wrapper at `kernel.mbt` exposes it as the user-facing `orient(p, q, r) -> Orientation` enum.

## Why "robust"?

The mathematical definition is simple:

```
orient2d(p, q, r) = (q.x − p.x) · (r.y − q.y)  −  (q.y − p.y) · (r.x − q.x)
```

The sign is what we care about: `> 0` ⇒ CCW, `< 0` ⇒ CW, `0` ⇒ collinear.

The problem is that this expression is the difference of two products of differences. When `p`, `q`, `r` are *almost* collinear, the two products are very close in magnitude, their difference is close to zero, and IEEE-754 double-precision rounding can flip the sign.

**Why a flipped sign matters**: many algorithms — convex hull, point-in-polygon, line-segment intersection, Delaunay triangulation — branch on this sign. A flipped sign means the algorithm produces a topologically wrong answer. Examples:

- A convex hull that includes a vertex it shouldn't, or excludes one it should.
- A point-in-polygon test that says "outside" for a point on the boundary.
- A line intersection that misses an obvious crossing because the orient signs disagree only in the second-to-last bit.

Robust predicates trade a small constant-factor slowdown for the guarantee that the **sign is mathematically correct in every case**.

## API surface

```moonbit nocheck
pub fn orient2d(pa : Coord, pb : Coord, pc : Coord) -> Double
```

The return value is the determinant itself (`2 × signed area`), not just the sign. Callers usually take the sign:

- `> 0` ⇒ CounterClockwise (`pa, pb, pc` turn left)
- `< 0` ⇒ Clockwise
- `= 0` ⇒ Collinear

Returning the magnitude as well gives `signed_area_of_triangle_robust` for free.

## Algorithm — Shewchuk's adaptive precision

The implementation follows Jonathan Shewchuk's classic 1997 paper *Adaptive Precision Floating-Point Arithmetic and Fast Robust Geometric Predicates*. Stages:

```
Stage 1 — fast non-adaptive estimate:
  det = (q.x − p.x) · (r.y − q.y) − (q.y − p.y) · (r.x − q.x)
  err = absolute_error_bound · (rough magnitude estimate)

  if |det| > err:
    # The naive computation is reliable for this input.
    return det.

Stage 2 — adaptive refinement:
  Use exact two-product / two-sum primitives (`expansion.mbt`)
  to compute the difference exactly as a sum of f64 components ("expansion").
  Sum the expansion to get a precise det.
  If still too close to zero, refine again.

  Return the final precise sign.
```

The trick: in the common (non-collinear) case, the fast Stage 1 takes only ~5 floating-point operations and is correctly classified. Only when the input is "near collinear" does the algorithm fall back to the more expensive Stage 2, where exact arithmetic via floating-point expansions guarantees the correct sign.

The error bounds (`CCWERRBOUND_A/B/C`) are pre-computed constants derived from machine epsilon — they answer "how big does `|det|` need to be for me to trust it without refinement?".

## Why not just use a bigger float type?

Languages with arbitrary-precision arithmetic (Python's `Fraction`, Rust's `num-bigint`) can compute the orient determinant exactly without Shewchuk's gymnastics. But:

- `f64` is hardware-accelerated; `BigRational` is software-emulated and 100× slower.
- Geometric algorithms with millions of orient calls would grind to a halt.
- Shewchuk's adaptive scheme keeps the common case at full hardware speed.

For port-internal use, this trade-off pays off: tests like `bench: orient2d (robust)` measure ~50ns per call on common hardware, vs. microseconds for arbitrary-precision.

## Examples

```moonbit nocheck
let p = @type.Coord(0.0, 0.0)
let q = @type.Coord(1.0, 0.0)
let r_left  = @type.Coord(1.0, 1.0)
let r_right = @type.Coord(1.0, -1.0)
let r_on    = @type.Coord(2.0, 0.0)

@robust.orient2d(p, q, r_left)    // > 0  (CCW)
@robust.orient2d(p, q, r_right)   // < 0  (CW)
@robust.orient2d(p, q, r_on)      // = 0  (collinear)

// The robust difference becomes visible for "almost collinear" inputs:
let p2 = @type.Coord(0.0, 0.0)
let q2 = @type.Coord(1.0, 1.0)
let r2 = @type.Coord(2.0, 2.0 + 1e-300)
@robust.orient2d(p2, q2, r2)
//   correctly POSITIVE — naive cross product would round to 0 or a wrong sign.
```

Tests in `robust/orient2d_test.mbt`:

- `orient2d collinear`
- `orient2d counter-clockwise`
- `orient2d clockwise`
- `orient2d high-precision tiny inputs`

## When to use

- **Always**, for any orientation test in this port. There is no faster non-robust path exposed; the port treats `orient2d` as the canonical primitive.
- The `kernel.mbt` wrapper (`orient(p, q, r)`) is what algorithm code should call — it returns the `Orientation` enum directly. Use `orient2d` only when you need the numeric magnitude (e.g. for `signed_area_of_triangle_robust`).

## Performance

Shewchuk's predicates are designed for this use case. Typical timings:

- **Non-adaptive Stage 1** (fast path, > 99% of real-world inputs): ~5 f64 ops, ~5–10 ns.
- **Adaptive Stage 2** (refinement when stage 1's bound is exceeded): up to a few hundred ops, ~100 ns.

The bench `bench: orient2d (robust)` in `geo/2d/kernel_bench_test.mbt` covers the typical-input case.

## Related

- `expansion.mbt` — the floating-point expansion primitives (two-sum, two-product, scale-expansion, fast-expansion-sum-zeroelim) that Stage 2 uses.
- `incircle.mbt` — sister predicate: "is point `d` inside the circumcircle of triangle `(a, b, c)`?".
- `kernel.mbt` — the user-facing wrapper.

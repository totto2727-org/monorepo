# `hausdorff_distance.mbt` — Hausdorff distance between two geometries

## Goal

Measure how **far apart two sets of points are** by asking:

> What is the largest distance from a point in set A to its nearest neighbour in set B (or vice versa, whichever is bigger)?

This is the **Hausdorff distance**. It's a metric on point sets — symmetric, non-negative, zero iff the sets are equal.

Hausdorff is order-insensitive (it cares about _what points are present_, not the order). It's stricter than "average distance" but more lenient than Fréchet: two polylines with the same points in different orders have **zero** Hausdorff distance but **large** Fréchet distance.

## API surface

```moonbit nocheck
pub fn hausdorff_distance_coords(a : Array[Coord], b : Array[Coord]) -> Double
pub fn hausdorff_distance_geometry(a : Geometry, b : Geometry) -> Double
```

Returns `0.0` for two identical sets (and for any pair of empty sets, by convention).

## Definition

For two non-empty sets `A` and `B` in the plane:

```
d(a, B)  = min over b ∈ B of euclidean_distance(a, b)      // a to its NN in B
d(A, B)  = max over a ∈ A of d(a, B)                       // worst case from A
H(A, B)  = max(d(A, B), d(B, A))                           // symmetric: take the worse direction
```

The two **directed** distances (`d(A, B)` and `d(B, A)`) can differ — one set might extend further from the other. Taking the max makes the result symmetric.

## Algorithm — naive O(n·m)

The implementation walks every point in `A`, finds its closest in `B`, tracks the running max, and then does the same in the reverse direction:

```
1. For each a ∈ A:
     d_a = min over b ∈ B of euclidean_distance(a, b)
     max_a_to_B = max(max_a_to_B, d_a)

2. For each b ∈ B:
     d_b = min over a ∈ A of euclidean_distance(a, b)
     max_b_to_A = max(max_b_to_A, d_b)

3. return max(max_a_to_B, max_b_to_A)
```

For the geometry-aware version, the port flattens both inputs to coord arrays via `coords_of_geometry` and then runs the same routine. This is a **vertex-only** Hausdorff: it ignores the interiors of edges. For polylines / polygons this can be conservative (result ≥ true continuous Hausdorff distance).

## Why "max of directed distances"?

Imagine `A = {(0, 0)}` (a single point at the origin) and `B = {(0, 0), (10, 0)}` (origin plus a far point):

```
d(A, B):  the only point in A is (0, 0); its NN in B is (0, 0) itself → 0.
d(B, A):  point (0, 0) ∈ B → NN in A is (0, 0) → 0.
          point (10, 0) ∈ B → NN in A is (0, 0) → 10.
          max = 10.

H(A, B) = max(0, 10) = 10.
```

The asymmetry: every point of `A` is _near_ `B`, but `B` has a stray point that's nowhere near `A`. The Hausdorff distance reflects that worst-case mismatch.

## Examples

```moonbit nocheck
let a = [@type.Coord(0.0, 0.0), @type.Coord(1.0, 0.0)]
let b = [@type.Coord(0.0, 0.0), @type.Coord(1.0, 0.0)]
@lib2d.hausdorff_distance_coords(a, b)             // 0.0  (identical sets)

let c = [@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0)]
@lib2d.hausdorff_distance_coords(a, c)             // 9.0  (point (10,0) is 9 units from nearest in `a`)
```

For polygons (geometry dispatch flattens to vertices):

```moonbit nocheck
let g1 = @type.Geometry::Polygon(...)   // some polygon
let g2 = @type.Geometry::Polygon(...)   // another
@lib2d.hausdorff_distance_geometry(g1, g2)
//   approximate Hausdorff, vertex-vs-vertex
```

Tests in `hausdorff_distance_test.mbt`:

- `hausdorff_distance: identical sets is 0`
- `hausdorff_distance: known case`

Property test (`property_test.mbt`):

- `property: hausdorff_distance is symmetric`.

Plus the bench `bench: hausdorff_distance n=50 vs n=50`.

## Performance

`O(n · m)` naive. For two sets of 50 points each, that's 2 500 distance computations — fast.

There exist faster algorithms for special cases (Hausdorff between convex polygons can be done in `O(n + m)` using rotating callipers; spatial-index-based methods do it in `O((n + m) log(n + m))` with R-tree / KD-tree pruning). The port doesn't currently implement those — the naive algorithm is good enough for vertex counts up to a few hundred.

## Caveats

- **Vertex-only**: doesn't measure the actual point-set distance for polylines / polygons; it's an over-approximation of the true continuous Hausdorff distance. Densify (`densify.mbt`) the inputs first for tighter bounds.
- **Outliers dominate**: a single faraway vertex pushes the result up. If your data has noise, consider Average Hausdorff (mean instead of max) — the port doesn't implement it but you can compose `coords_iter` + `euclidean_distance` yourself.
- **Empty sets**: by convention the port returns `0` for two empty sets; for one empty + one non-empty, it returns `0` too (no points to disagree about). Some libraries return `+∞` instead — check before relying on the result for empty inputs.

## Comparison with Fréchet

See `frechet_distance.mbt.md`'s "Comparison with Hausdorff" section.

## Related

- `frechet_distance.mbt` — order-respecting curve metric.
- `euclidean.mbt` — pairwise distance primitive used everywhere in this algorithm.
- `coords_iter.mbt` — flattens geometries to vertex arrays for the geometry-aware variant.

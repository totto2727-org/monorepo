# `frechet_distance.mbt` — Fréchet distance between two line strings

## Goal

Measure how **similar two polylines are as continuous curves**, by asking the question:

> If a person walks along curve A and a dog walks along curve B (both can choose their pace independently but cannot walk backward), what is the **minimum length of leash** required so the dog and human stay tethered the whole time?

The answer is the **discrete Fréchet distance**, a single `Double`. Smaller = the curves are more similar.

Unlike Hausdorff distance (which only checks "every point of A is close to _some_ point of B"), Fréchet distance respects the **order** of the points along each curve. Two polylines that pass through the same set of points but in opposite orders have a small Hausdorff distance but a large Fréchet distance.

## API surface

```moonbit nocheck
pub fn frechet_distance(a : LineString, b : LineString) -> Double
```

Returns:

- `0.0` if either line string is empty (degenerate case, treated as "fits inside any leash").
- The discrete Fréchet distance otherwise.

## Algorithm — dynamic programming

The implementation computes the **discrete** Fréchet distance: the leash measure where both walkers are constrained to vertex stops (not arbitrary points along edges). For most practical purposes the discrete and continuous variants are very close.

Build an `n × m` matrix `dp` where `dp[i][j]` is the minimum leash length required if A's walker is at vertex `aᵢ` and B's walker is at vertex `bⱼ`, having traversed both curves in legal order:

```
dp[0][0] = euclidean_distance(a[0], b[0])

dp[i][0] = max(dp[i−1][0],   euclidean_distance(a[i], b[0]))      // B stays put at b₀
dp[0][j] = max(dp[0][j−1],   euclidean_distance(a[0], b[j]))      // A stays put at a₀

dp[i][j] = max(
  min(dp[i−1][j], dp[i−1][j−1], dp[i][j−1]),   // best previous state
  euclidean_distance(a[i], b[j])                // current leash needed
)
```

The result is `dp[n−1][m−1]` — the minimum leash that gets both walkers all the way to the end.

The intuition: at each cell, you choose the best move (advance A only, advance B only, or advance both) and combine that "running max" with the leash you'd need _right now_ between the current pair of vertices. The `max` captures "the leash must be long enough for every moment, not just the final one"; the `min` captures "you can pick whichever previous state is best".

## Step-by-step (a 3-vertex line vs. a 4-vertex line)

```
A:  a₀ — a₁ — a₂              n = 3
B:  b₀ — b₁ — b₂ — b₃          m = 4

Build a 3 × 4 dp matrix:

       b₀     b₁     b₂     b₃
   a₀ [...] [...] [...] [...]
   a₁ [...] [...] [...] [...]
   a₂ [...] [...] [...] [.✓.]   ← result is bottom-right

Each cell is computed in row-major order; each only depends on its top, left,
and top-left neighbours.
```

The answer is `dp[2][3]`.

## Why max-of-running-max?

Fréchet distance is fundamentally a **min-over-paths-of-max-along-path** problem. The walker pair traces some path through the matrix from `(0, 0)` to `(n−1, m−1)`; the "leash needed" is the _maximum distance_ over all cells on the path. We want to **minimise that maximum**, so the DP recurrence is:

- `min` over the three previous cells (best path so far).
- `max` against the current cell's distance (the leash can only get longer, not shorter, as we advance).

## Examples

```moonbit nocheck
// Identical line strings → 0
let l = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)])
@lib2d.frechet_distance(l, l)                              // 0.0

// Parallel lines offset by 1 unit perpendicular → leash = 1.0
let above = @type.LineString::from_tuples([(0.0, 1.0), (1.0, 1.0), (2.0, 1.0)])
@lib2d.frechet_distance(l, above)                          // 1.0

// One empty line string → 0
let empty = @type.LineString::empty()
@lib2d.frechet_distance(l, empty)                          // 0.0
```

Tests in `frechet_distance_test.mbt`:

- `frechet_distance: identical lines is 0`
- `frechet_distance: parallel translated lines`
- `frechet_distance: empty lines`

Property test (`property_test.mbt`):

- `property: frechet_distance >= euclidean_distance of endpoints` — the leash must always be at least as long as the start-to-start and end-to-end distances.

Plus the bench `bench: frechet_distance n=20 vs n=20`.

## Performance

`O(n · m)` time and space — the algorithm fills the whole `dp` matrix. For two 100-vertex polylines that's 10 000 cells, which is fast on modern hardware (sub-millisecond). For very large inputs (n, m > 1000s), the space dominates.

There exist `O(n · m)`-time-but-`O(min(n, m))`-space implementations using rolling arrays, but the port chose the simpler matrix form for clarity. The benchmark is at `n = 20`, the typical use case.

## Comparison with Hausdorff

| Property                          | Fréchet                 | Hausdorff                                |
| --------------------------------- | ----------------------- | ---------------------------------------- |
| Respects order along the curve    | Yes                     | No                                       |
| Symmetric                         | Yes                     | Yes                                      |
| Triangle inequality               | Yes (it's a metric)     | Yes                                      |
| Result for two reversed polylines | Large (curves disagree) | Same as forward (Hausdorff is unordered) |
| Cost                              | `O(n · m)`              | `O(n · m)` naive, `O((n + m) log)`-able  |

Use **Fréchet** when "did this GPS track follow this road?" — order matters.

Use **Hausdorff** (`hausdorff_distance.mbt`) when "are these point clouds in the same area?" — order doesn't.

## Caveats

- Discrete variant (vertex-only stops). For polylines with widely-spaced vertices and short matching curves, the result can be larger than the continuous Fréchet distance. Densify (`densify.mbt`) the inputs first if you need a tighter bound.
- No tolerance for noise: a single outlier vertex in either curve raises the distance to "leash long enough to span that outlier".

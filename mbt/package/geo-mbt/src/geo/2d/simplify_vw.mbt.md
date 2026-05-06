# `simplify_vw.mbt` — Visvalingam–Whyatt polyline simplification

## Goal

Reduce vertex count in a polyline by repeatedly removing the **vertex whose elimination causes the smallest area change**, until removing the next would exceed a tolerance.

VW is a sibling of RDP (`simplify.mbt`) with a different metric: instead of perpendicular distance, it scores each vertex by the **area of the triangle it forms with its two neighbours**. Vertices on near-straight stretches form near-zero-area triangles and are removed first; vertices at sharp corners form large-area triangles and survive.

This produces a more **visually pleasing** decimation than RDP: small wiggles fade out gradually as the tolerance grows, while sharp features are preserved until very high tolerances.

## API surface

```moonbit nocheck
pub fn simplify_vw_line_string(ls : LineString, epsilon : Double) -> LineString
```

`epsilon` is the **minimum triangle area** a vertex must contribute to survive. Larger `epsilon` removes more vertices.

## Algorithm — area-based decimation

```
1. For every interior vertex i (i.e. neither first nor last), compute its
   "effective area":
     area_i = | signed_area_of_triangle(coords[i-1], coords[i], coords[i+1]) |

2. While there exists an interior vertex with area_i < epsilon:
   a. Find the vertex with the smallest area_i.
   b. Remove it.
   c. Re-compute the area for its (new) neighbours, since their triangles
      have changed.
```

A heap or priority queue makes step 2a `O(log n)` per removal, giving `O(n log n)` overall. The port currently uses a straightforward array implementation that may be `O(n²)` for adversarial inputs but is simple and correct for typical sizes.

## Step-by-step

```
input: A — B — C — D — E    epsilon = 0.5

triangle areas:
  B: area(A, B, C) = 0.3
  C: area(B, C, D) = 1.2
  D: area(C, D, E) = 0.4

smallest is B (0.3) < 0.5 → remove B

remaining: A — C — D — E

re-compute area for C (its left neighbour changed from B to A):
  C: area(A, C, D) = 0.7    (let's say)
D's triangle is unchanged from before:
  D: area(C, D, E) = 0.4

smallest is D (0.4) < 0.5 → remove D

remaining: A — C — E    (C's area might re-grow as well; loop continues)

eventually no remaining interior vertex has area < 0.5 → done
```

## Variant: "preserve" form

Upstream `geo` provides `SimplifyVwPreserve`, a topology-preserving variant that refuses to remove vertices whose elimination would introduce a self-intersection. The port currently provides only the **simple** form.

For inputs that may self-intersect after simplification, follow up with `validation.mbt`'s `is_valid` and re-simplify with a smaller `epsilon` if needed.

## Examples

```moonbit nocheck
// Remove the lowest-area interior vertex
let ls = @type.LineString::from_tuples([
  (0.0, 0.0), (1.0, 0.05), (2.0, 0.0), (3.0, 1.0), (4.0, 0.0)
])
@lib2d.simplify_vw_line_string(ls, 0.5)
//   The vertex (1, 0.05) forms a tiny triangle with its neighbours and is the
//   first to drop. (3, 1) forms a large triangle and stays.
//   Result: roughly [(0, 0), (2, 0), (3, 1), (4, 0)]
```

Tests in `simplify_test.mbt`:

- `simplify_vw removes the lowest-area triangle`

## Comparison with RDP

| Property                         | RDP                        | VW (this file)            |
| -------------------------------- | -------------------------- | ------------------------- |
| Cost metric                      | Perpendicular distance     | Triangle area             |
| Output proximity to input        | Bounded by `epsilon` (Hausdorff) | Bounded by cumulative dropped area |
| Sensitivity to small wiggles     | Sharp threshold            | Gradual                   |
| Sensitivity to spikes            | Spikes survive if > `epsilon` | Tall thin spikes survive (large area) |
| Topology preservation            | No                         | No (simple form)          |
| Speed                            | `O(n log n)` avg           | `O(n log n)` with heap    |

The choice depends on what "similar to the original" means in your application:

- "Every dropped vertex within X metres" → **RDP**.
- "Small features removed first, big ones last" → **VW**.

For map rendering at progressively coarser zoom levels, VW often gives nicer results because the simplification "fades out" small detail before big detail.

## Edge cases

- **`epsilon ≤ 0`**: no vertex has area < 0; output equals input.
- **0–2 input coords**: returned unchanged.
- **Endpoints**: never removed by VW (they have no triangle).
- **All-collinear inputs**: every interior triangle has area 0, so all interior vertices are removed. Output is just the two endpoints.

## Performance

Implementation-dependent. The textbook version with a min-heap runs in `O(n log n)`. The port uses a simpler approach that's straightforward to read; for inputs of < a few thousand coords this is fast enough.

## Related

- `simplify.mbt` — RDP simplifier.
- `chaikin_smoothing.mbt` — orthogonal: smooths corners.
- `area.mbt` — `signed_area_of_triangle` underpins each vertex's "effective area" score.

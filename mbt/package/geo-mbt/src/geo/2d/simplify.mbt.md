# `simplify.mbt` — Ramer–Douglas–Peucker (RDP) polyline simplification

## Goal

Reduce the number of vertices in a polyline while keeping its shape **visually similar to the original**. The output has strictly fewer (or equal) coords than the input; every dropped coord is within a tolerance `epsilon` of the simplified line.

The classic use cases:

- **Map rendering**: when zoomed out, you don't need every wiggle of a coastline.
- **GPS track storage**: drop redundant points on a straight road.
- **Output compression**: smaller payloads when serving line geometries.

## API surface

```moonbit nocheck
pub fn simplify_line_string(ls : LineString, epsilon : Double) -> LineString
pub fn simplify_polygon(p : Polygon, epsilon : Double) -> Polygon
pub fn simplify_line_string_indices(ls : LineString, epsilon : Double) -> Array[Int]
```

`epsilon` is the **tolerance** — the maximum perpendicular distance from a dropped vertex to the simplified line. A larger `epsilon` produces a coarser simplification.

`simplify_line_string_indices` returns the **indices** of the kept vertices instead of a new LineString. Useful when you have parallel arrays (e.g. timestamps) and need to subset them in the same way.

## Algorithm — Ramer–Douglas–Peucker

A divide-and-conquer recursion:

```
simplify(coords, lo, hi, epsilon):
  if hi - lo < 2:
    return [coords[lo], coords[hi]]               # trivial: just keep endpoints

  # Find the vertex farthest from the chord (coords[lo], coords[hi]).
  d_max = 0
  k = lo
  for i in lo+1 .. hi:
    d = perpendicular_distance(coords[i], chord)
    if d > d_max:
      d_max = d
      k = i

  if d_max <= epsilon:
    return [coords[lo], coords[hi]]               # entire span fits within epsilon — drop interior

  # Otherwise, the farthest vertex is too far to drop.
  # Keep it, and recurse on the two halves.
  left  = simplify(coords, lo, k, epsilon)
  right = simplify(coords, k, hi, epsilon)

  return left + right (deduplicating the shared coords[k])
```

The intuition: at each level, we ask "can the entire span lo..hi be replaced by a single straight chord without distorting any interior point by more than `epsilon`?" If yes, drop everything between. If no, the worst-offender vertex must be kept; split there and recurse.

```
input:           a • • • • • b
                    ↑   ↑
                  d=2  d=4         epsilon = 3

worst offender at index 4 with d=4 > 3 → keep it, split:
                a • • • • • b
                ↑   ↑   ↑   ↑
              keep    keep keep  (recurse on [a..k] and [k..b])

recurse left: chord (a, k), check interior of [1..3], etc.
recurse right: chord (k, b), check interior of [5..6], etc.

result: a, k, ..., b   (a subset of input)
```

## Step-by-step (4-coord example)

```
input:   [(0, 0), (1, 0.5), (2, 0.1), (5, 0)]    epsilon = 1.0

initial recursion call: simplify(0..3)
  chord:  (0, 0) → (5, 0)   (the line y = 0 between x = 0 and x = 5)
  perpendicular distances of interior points:
    (1, 0.5):  d = 0.5
    (2, 0.1):  d = 0.1
  worst offender: (1, 0.5)  with d = 0.5
  is 0.5 > epsilon (= 1.0)? no → drop interior
  return [(0, 0), (5, 0)]

result: 2-coord simplified line
```

## Examples

```moonbit nocheck
// Drop nearly-colinear interior points
let ls = @type.LineString::from_tuples([
  (0.0, 0.0), (1.0, 0.1), (2.0, -0.1), (3.0, 0.05), (5.0, 0.0)
])
@lib2d.simplify_line_string(ls, 0.5)
//   roughly [(0, 0), (5, 0)] — interior dropped

// epsilon = 0 keeps everything (no point is "close enough" to drop)
@lib2d.simplify_line_string(ls, 0.0)
//   == ls (unchanged)

// Indices form: which coords were kept?
@lib2d.simplify_line_string_indices(ls, 0.5)
//   [0, 4]
```

For a polygon, simplification is applied **per ring** (exterior + each interior). The result is a new polygon with fewer vertices but the same number of rings:

```moonbit nocheck
@lib2d.simplify_polygon(polygon, 1.0)
```

Tests in `simplify_test.mbt`:

- `simplify line with eps=0 keeps all`
- `simplify removes nearly colinear points`
- `simplify line < 3 coords is unchanged`

Property test (`property_test.mbt`):

- `property: simplify preserves first and last coord` — RDP guarantees the endpoints of the polyline are never dropped.

Plus the bench `bench: simplify_line_string RDP eps=0.5`.

## Why "perpendicular distance"?

The "distance from a point to a line segment" used here is the perpendicular drop onto the chord — see `euclidean_distance_coord_to_line` in `euclidean.mbt`. That makes RDP **shape-preserving in a metric sense**: every dropped vertex is within `epsilon` of the simplified line, so the simplification's Hausdorff distance from the original is bounded by `epsilon`.

This is the property that makes RDP a good general-purpose simplifier: it gives a metric guarantee.

## Edge cases

- **`epsilon ≤ 0`**: every interior point is "too far" to drop. Output equals input.
- **0–2 input coords**: returned unchanged (nothing to simplify).
- **Self-intersecting line strings**: simplified blindly. The output may have its self-intersections in different places, or new ones introduced. RDP **does not preserve topology** — it just preserves the metric proximity. Use VW (`simplify_vw.mbt`) if topology matters.
- **Polygon rings**: simplifying a ring can collapse it to fewer than 3 distinct points (a "non-polygon"). The port doesn't currently guard against this — a heavily over-simplified polygon may end up structurally invalid.

## Performance

Average case: `O(n log n)` from the divide-and-conquer split. Worst case: `O(n²)` when every point is the farthest in its sub-range (zig-zag pattern). For typical real-world data the average case dominates.

## Comparison with VW

| Property                  | RDP                                       | Visvalingam–Whyatt                   |
| ------------------------- | ----------------------------------------- | ------------------------------------ |
| Cost metric               | Perpendicular distance                    | Triangle area                        |
| Output proximity to input | Bounded by `epsilon` (Hausdorff)          | Bounded by area cumulatively         |
| Sensitivity to spikes     | High — keeps spikes that exceed `epsilon` | Lower — small-area spikes drop early |
| Topology preservation     | No                                        | No (simple form)                     |
| Speed                     | `O(n log n)` avg                          | `O(n log n)` with heap               |

RDP is the **default** choice when you want metric proximity guarantees. VW is a better choice when you want **smooth visual decimation** (small features fade out gradually as `epsilon` grows).

## Related

- `simplify_vw.mbt` — Visvalingam–Whyatt alternative.
- `chaikin_smoothing.mbt` — orthogonal: smooths corners (and adds vertices) instead of removing.
- `euclidean.mbt` — the perpendicular-distance primitive.

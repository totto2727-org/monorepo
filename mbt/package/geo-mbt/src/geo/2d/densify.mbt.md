# `densify.mbt` — insert sub-vertices along long segments

## Goal

Take a line string or polygon and add **extra vertices along its edges** so that no edge is longer than a target maximum. The output represents the **same geometry shape** but with finer resolution.

Useful when:

- Computing distance metrics that depend on vertex spacing (Hausdorff, Fréchet) — densifying first gives a tighter bound on the true continuous metric.
- Resampling a polyline at uniform spacing for analysis or rendering.
- Reprojecting a geometry across coordinate systems where straight lines in the source CRS aren't straight in the target — adding intermediate vertices reduces projection error.

## API surface

```moonbit nocheck
pub fn densify_line_string(ls : LineString, max_segment_length : Double) -> LineString
pub fn densify_polygon(p : Polygon, max_segment_length : Double) -> Polygon
```

`max_segment_length` must be positive. Edges already shorter than this are kept as-is.

## Algorithm

For each segment `(a, b)` in the input:

1. Compute `len = euclidean_distance(a, b)`.
2. If `len ≤ max_segment_length`: keep the segment as-is (just emit `a`; `b` will come from the next segment's start).
3. Otherwise: split the segment into `n = ceil(len / max_segment_length)` equal-length sub-segments, emitting `n − 1` interior vertices.

The interior vertices are placed evenly along the segment using linear interpolation:

```
for i in 1..n:
  t = i / n
  emit  a + t · (b − a)
```

After the last segment, the final coord `b` is appended once. The result has the same start and end as the input.

```
input:  [(0, 0), (10, 0)],  max_segment_length = 3

len = 10 → n = ceil(10 / 3) = 4 → 3 interior vertices

output: [(0, 0), (2.5, 0), (5, 0), (7.5, 0), (10, 0)]
```

For `densify_polygon`, the algorithm is applied to the exterior ring and every interior ring independently.

## Why `ceil` not `round`?

Using `ceil` guarantees no output edge exceeds `max_segment_length`. With `round`, a 10-unit segment with `max = 3` would split into 3 sub-segments of length 3.33 — slightly over the cap. `ceil` yields 4 sub-segments of length 2.5 — strictly under the cap.

The trade-off is more vertices than strictly necessary. For analysis purposes (where the cap is what matters), this is the right call.

## Examples

```moonbit nocheck
// Long segment gets split

///|
let ls = @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0)])

///|
let dense = @lib2d.densify_line_string(ls, 3.0)
// dense.coords() == [(0,0), (2.5,0), (5,0), (7.5,0), (10,0)]
//   max edge length: 2.5 (≤ 3)

// Already-short segments left alone

///|
let short = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)])

///|
let result = @lib2d.densify_line_string(short, 5.0)
// result == short.coords()
```

Tests in `densify_test.mbt`:

- `densify_line_string: long segment gets split`
- `densify_line_string: short segment unchanged`

## Edge cases

- **`max_segment_length ≤ 0`**: behaviour undefined — the implementation may divide by zero or loop forever depending on input. The port doesn't guard explicitly; callers should pre-validate.
- **Empty / single-coord line string**: returned unchanged (no segments to split).
- **Closed ring** (polygon): the implicit closing edge is densified along with the rest. The output is also closed.

## Performance

`O(n + total_added_vertices)`. The algorithm is single-pass: for each input segment, compute the split count once, emit the right number of interpolated coords. No allocations beyond the output array.

## Caveats

- The densification is **uniform along each segment**. If you need uniform spacing along the _entire line string_ (so the gap between vertex 5 and 6 equals the gap between vertex 17 and 18), use `line_string_interpolate_point` in a loop instead — `densify_line_string` aligns each segment's vertices to its own endpoints, which can produce slightly uneven spacing across segment boundaries.
- For very sharp corners, densification doesn't smooth — the corner remains exactly at the original vertex. To smooth corners, use `chaikin_smoothing.mbt` (orthogonal operation).
- For projecting a geometry across CRSs, run densify first **then** project — projecting first leaves long edges that may bow under the projection.

## Related

- `chaikin_smoothing.mbt` — adds vertices and bends them around corners. Smooths AND densifies.
- `simplify.mbt` — the inverse: removes vertices to coarsen a polyline.
- `line_interpolate_point.mbt` — for one-off interpolation queries; densify is the bulk version.

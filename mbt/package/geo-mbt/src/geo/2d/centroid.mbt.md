# `centroid.mbt` — geometric centroid

## Goal

Find the **centroid** (geometric centre / centre of mass under uniform density) of a 2D shape. The centroid is what you'd balance the shape on if it were a rigid plate of uniform thickness.

The centroid coincides with the **average of the vertices** only for triangles. For more complex shapes the formula is weighted by area.

## API surface

| Function                              | Returns        | Empty input |
| ------------------------------------- | -------------- | ----------- |
| `centroid_polygon(p)`                 | `Point?`       | `None` when exterior is empty / has no area |
| `centroid_multi_polygon(mp)`          | `Point?`       | `None` when no member contributes any area  |
| `centroid_line_string(ls)`            | `Point?`       | `None` when `ls` has 0 coords; uses arc-length weighting otherwise |
| `centroid_geometry(g)`                | `Point?`       | Dispatch — picks the right per-shape formula |

There's also a port-side trait `HasCentroid { centroid(self) -> Point? }` with impls for `Geometry`, `LineString`, `Polygon`, `MultiPolygon` so callers can write generic code.

## Why area-weighted?

Imagine a polygon shaped like the letter "L". The "average of vertices" would skew toward the long arm because that arm has more vertices, even though both arms might be equally large in area. To get a centroid that doesn't depend on **how many points** describe the shape (only on the shape itself), each piece needs to be weighted by its **size**.

For a 2D shape:

- **Polygons**: weight by **area**. Each triangle in a fan decomposition contributes `(centroid_of_triangle, signed_area_of_triangle)`.
- **Line strings (1D)**: weight by **arc length**. Each segment contributes `(midpoint, length)`.
- **Points (0D)**: an unweighted average — but the port doesn't expose a `centroid_multi_point` because that case is degenerate to compute.

## Algorithm — polygon

For a simple polygon:

```
For each edge (pᵢ, pᵢ₊₁) of the exterior ring:
  c   ← (pᵢ + pᵢ₊₁) / 2          // segment midpoint
  Aᵢ  ← (pᵢ × pᵢ₊₁) / 2          // signed triangle area (shoelace term)
  cx_sum += c.x · Aᵢ
  cy_sum += c.y · Aᵢ
  area_sum += Aᵢ

centroid = (cx_sum / area_sum, cy_sum / area_sum)
```

This is the well-known formula derived from integrating `∫∫ (x, y) dA` over the polygon's interior using Green's theorem. It works for any simple polygon (convex or concave). For polygons with **holes**, run the same accumulator over each interior ring with sign-flipped contributions, and the centroid of the holed polygon falls out automatically.

For `MultiPolygon`, run the per-polygon centroid as a (centroid, area) weighted point and average over the multi-polygon's components.

If the **total signed area is 0** (degenerate polygon — collinear, self-cancelling), the formula divides by zero. The port detects this and returns `None`.

## Algorithm — line string

A line string is one-dimensional, so it has no area. The centroid is the **length-weighted average of the segment midpoints**:

```
For each segment (pᵢ, pᵢ₊₁):
  midpoint ← (pᵢ + pᵢ₊₁) / 2
  length   ← euclidean_length(pᵢ → pᵢ₊₁)
  cx_sum   += midpoint.x · length
  cy_sum   += midpoint.y · length
  total    += length

centroid = (cx_sum / total, cy_sum / total)
```

Same idea as the polygon formula, just integrating over arc length instead of area. A degenerate line string (all coords identical, total length 0) returns `None`.

## Examples

```moonbit nocheck
// Centroid of the unit square is (0.5, 0.5)

///|
let unit_square = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]),
  [],
)

///|
let c = @lib2d.centroid_polygon(unit_square).unwrap()
// c.x() == 0.5, c.y() == 0.5
```

For a triangle, the centroid is the **average of the three vertices**:

```moonbit nocheck
let triangle = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0), (0.0, 3.0)]),
  [],
)
@lib2d.centroid_polygon(triangle).unwrap()  // (1.0, 1.0)
```

For an L-shape (concave), the centroid sits inside the bounding box but **not at its centre** — pulled toward the bulkier side.

Tests in `centroid_test.mbt`:

- `centroid of unit square is (0.5, 0.5)`
- `centroid of triangle is (avg, avg)`
- `centroid of rect is rect.center`

Property test (`property_test.mbt`):

- `property: centroid is inside (or on boundary of) convex polygon` — runs on randomly-generated convex polygons.

## Edge cases

- **Empty geometry** ⇒ `None`.
- **Zero area / zero length** (degenerate input that contributed nothing) ⇒ `None`. This is what makes the return type `Point?` rather than `Point`.
- **Self-intersecting polygons** (bowtie) ⇒ the formula still produces a value, but it's not geometrically meaningful. Run `validation.mbt` upstream if your input may be invalid.
- **Polygon with a hole**: the centroid lies between the centroids of the exterior and the interior, weighted by their areas (with the interior contributing negative weight).

## Performance

`O(n)` with `n` = total coords. One pass per ring, no allocation. Benchmarked as `bench: centroid_polygon n=100` (`centroid_bench_test.mbt`).

## Related

- `extremes.mbt` — for "the four corner-most points" rather than a single centre point.
- `area.mbt` — `signed_area_of_polygon` is the denominator of the centroid formula.
- `bounding_rect.mbt` — `Rect::center()` gives the **bounding box centre** which is *not* the centroid of an irregular polygon.

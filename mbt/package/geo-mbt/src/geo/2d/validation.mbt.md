# `validation.mbt` — geometry well-formedness checks

## Goal

Check whether a geometry is **structurally well-formed** according to the OGC Simple Features Access spec. Returns either a yes/no boolean or a list of specific structural problems.

This is the **pre-flight check** before running algorithms that assume valid input — many functions in this package have undefined behaviour on invalid geometries (self-intersecting polygons, rings with too few coords, non-finite coords, etc.).

## API surface

```moonbit nocheck
pub(all) enum ValidationProblem {
  TooFewPoints       // a LineString with fewer coords than needed
  RingNotClosed      // a polygon ring whose first ≠ last
  RingTooFewPoints   // a polygon ring with < 4 coords (3 + closing duplicate)
  SelfIntersection   // a ring whose edges cross
  NonFiniteCoord     // a coord containing NaN / ±Inf
}

pub fn is_valid(g : Geometry) -> Bool
pub fn validation_problems(g : Geometry) -> Array[ValidationProblem]
```

`is_valid` is the convenient `Bool`-only form. `validation_problems` returns the **list of problems** found (potentially empty).

`is_valid(g) == validation_problems(g).length() == 0`.

## What's checked

| Type                 | Validity criteria                                                                                                                        |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `Coord`              | both `x` and `y` are finite (not NaN / Inf)                                                                                              |
| `Point`              | wraps a valid `Coord`                                                                                                                    |
| `Line`               | both endpoints valid                                                                                                                     |
| `LineString`         | every coord finite. `≥ 2` coords (a 0- or 1-coord LineString reports `TooFewPoints`)                                                     |
| `Polygon`            | exterior + each interior ring: each is a valid LineString, has `≥ 4` coords (3 unique + 1 closing repeat), is closed, doesn't self-cross |
| `MultiPolygon`       | every member polygon is valid                                                                                                            |
| `Rect`               | `min` and `max` are finite                                                                                                               |
| `Triangle`           | all 3 vertices finite                                                                                                                    |
| `GeometryCollection` | every member is valid                                                                                                                    |
| `Geometry`           | dispatch                                                                                                                                 |

## What's NOT checked

The port checks **structural** validity only. It does **not** check:

- **Polygon orientation** (CCW exterior, CW interiors) — the port doesn't enforce winding.
- **Hole containment** (interior rings inside the exterior, not overlapping each other) — out of scope; would require multi-ring intersection tests.
- **MultiPolygon non-overlap** between members.
- **Geometric simplicity** of LineStrings (i.e. self-intersections in 1-D paths). Only polygon rings are checked for self-intersection.

For a stricter validity check, future scope work could add `OverlapRing`, `HoleNotInExterior`, etc., problem variants.

## Algorithm — `SelfIntersection`

The most expensive check. For each ring, walk pairs of non-adjacent edges and test whether they intersect:

```
for i in 0..n-1:
  for j in i+2..n-1:                        # skip adjacent edges
    if intersects_line_line(edge[i], edge[j]):
      return SelfIntersection
```

Adjacent edges share a vertex by definition — that vertex isn't a self-intersection, so we skip those pairs. The wrap-around pair `(edge[n-1], edge[0])` is also skipped.

Naively `O(n²)`. The port currently uses this naive form; a sweep-line algorithm would bring it to `O((n + k) log n)` where `k` is the number of intersections found, but that's deferred (sweep-line is post-scope).

## Examples

```moonbit nocheck
let valid_polygon = @type.Geometry::Polygon(@type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [],
))
@lib2d.is_valid(valid_polygon)               // true
@lib2d.validation_problems(valid_polygon)    // []

let too_few = @type.Geometry::LineString(@type.LineString::from_tuples([(0.0, 0.0)]))
@lib2d.is_valid(too_few)                     // false
@lib2d.validation_problems(too_few)          // [TooFewPoints]

let self_crossing = @type.Geometry::Polygon(@type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 10.0), (0.0, 10.0), (10.0, 0.0)]),  // bowtie
  [],
))
@lib2d.is_valid(self_crossing)               // false
@lib2d.validation_problems(self_crossing)    // [SelfIntersection]

let nan_polygon = @type.Geometry::Polygon(@type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, @double.not_a_number), (0.0, 10.0), (0.0, 0.0)]),
  [],
))
@lib2d.is_valid(nan_polygon)                 // false
@lib2d.validation_problems(nan_polygon)      // [NonFiniteCoord]
```

Tests in `validation_test.mbt`:

- `valid polygon`
- `linestring with 1 coord is invalid`
- `valid linestring`
- `non-finite coord is invalid`
- `ring with too few points is invalid`

## Difference from upstream's spec

Upstream `geo` exposes a finer-grained `Validation` trait with `RingRole` (Exterior / Interior(idx)) and `CoordIndex` carrying the exact coord at fault. The port flattens these into a single enum `ValidationProblem` without the location information — the trade-off is simplicity at the cost of "which coord exactly was wrong" (you'd re-walk the geometry to find it).

For most port-internal usage the port-side flattened form is sufficient; if you need exact locations, walk `coords_iter` yourself and re-classify.

## When to call

- **Before** running any algorithm that assumes simple polygons (`bool_ops.mbt`'s clipping, `centroid_polygon`, `signed_area_of_polygon`, `coordinate_position_for_polygon`).
- **After** any operation that may have introduced invalidity: `simplify_*`, `map_coords_in_*` with a possibly-bad function, deserialised geometries from external sources.
- **Never** from inside a hot loop — `SelfIntersection` is `O(n²)`. Validate once at the boundary, then trust the input through the rest of the pipeline.

## Performance

- `TooFewPoints`, `RingNotClosed`, `RingTooFewPoints`, `NonFiniteCoord`: `O(n)` each.
- `SelfIntersection`: `O(n²)` per ring.

For typical polygons of a few hundred vertices this is sub-millisecond. For very large polygons (10k+ vertices) the self-intersection check dominates.

## Related

- `dimensions.mbt` — orthogonal: even a "valid" polygon can be 1-D (degenerate area). They check different things.
- `is_convex.mbt` — orthogonal: a self-intersecting polygon may still appear "convex" by this file's loose check; combining `is_convex` with `is_valid` covers both.

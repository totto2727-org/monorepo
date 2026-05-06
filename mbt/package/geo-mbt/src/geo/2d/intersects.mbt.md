# `intersects.mbt` — do two geometries share any point?

## Goal

Decide whether two geometries have **at least one point in common** — without computing the actual intersection. The output is just `Bool`. This is the cheaper, decision-only sibling of `bool_ops.mbt` (which would compute the intersection geometry).

`intersects(a, b)` is the symmetric companion of `contains` — `a` intersects `b` iff `a` and `b` share *any* point (interior, boundary, anywhere).

## API surface

The port provides one function per (geometry-type, geometry-type) pair, plus a `Geometry` dispatch:

```moonbit nocheck
pub fn intersects_coord_coord(a, b)             -> Bool
pub fn intersects_coord_line(c, l)              -> Bool
pub fn intersects_coord_line_string(c, ls)      -> Bool
pub fn intersects_coord_polygon(c, p)           -> Bool
pub fn intersects_line_line(a, b)               -> Bool
pub fn intersects_line_line_string(l, ls)       -> Bool
pub fn intersects_line_polygon(l, p)            -> Bool
pub fn intersects_line_string_line_string(a, b) -> Bool
pub fn intersects_polygon_polygon(a, b)         -> Bool
pub fn intersects_rect_coord(r, c)              -> Bool
pub fn intersects_geometry(a, b)                -> Bool   // dispatch on both arguments
```

## Algorithm strategies

The implementation picks the cheapest strategy for each pair:

### Coord vs anything

- `coord vs coord`: equality check.
- `coord vs line`: `coord_on_line` (collinear AND parametric `t ∈ [0, 1]`).
- `coord vs line string`: any segment contains it.
- `coord vs polygon`: `coord_position_for_polygon != Outside`.
- `coord vs rect`: bbox containment check.

### Segment vs segment (`Line` vs `Line`)

This is the classic segment-segment intersection test. Uses **four orientation checks**:

```
Let segments be (p1, p2) and (q1, q2).
o1 = orient(p1, p2, q1)
o2 = orient(p1, p2, q2)
o3 = orient(q1, q2, p1)
o4 = orient(q1, q2, p2)

The segments cross iff (o1 ≠ o2) AND (o3 ≠ o4).
Special-case: if any oᵢ == Collinear, fall back to a parametric overlap test.
```

The "different orientation on each side" is a consequence of the segments going from one side of the other to the other — a topological argument that doesn't need the actual intersection coordinate, just signs.

The collinear case requires a separate test because the formula above gives `Collinear == Collinear` for both endpoint orientations and would say "no intersection". `intersects_line_line` falls back to checking whether the two collinear segments **overlap** along their shared line (using parametric `t` ranges).

### Line / segment vs line string

Walk each segment of the line string, run `intersects_line_line` against the input line. Return `true` on the first hit.

### Polygon vs anything

A polygon is a 2-D region, so "intersection" includes all of: *touching at the boundary*, *one shape inside the other*, *boundaries crossing*. The implementation handles each:

```
intersects_polygon_X(p, x):
  1. bbox-vs-bbox quick reject (returns false when bboxes don't overlap)
  2. boundary edges of p vs x: any segment-segment crossing? → true
  3. any vertex of x inside p?                              → true
  4. any vertex of p inside x?                              → true
  5. otherwise                                              → false
```

The vertex-in-polygon checks (steps 3 and 4) handle the "one shape entirely contained inside the other without any boundary crossing" case.

### Polygon vs polygon

Same shape as above but with both vertex-in-polygon directions. Handles holes correctly because `coord_position_for_polygon` already accounts for them.

## Examples

```moonbit nocheck
let l1 = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
let l2 = @type.Line::Line(@type.Coord(0.0, 10.0), @type.Coord(10.0, 0.0))
@lib2d.intersects_line_line(l1, l2)    // true (cross at (5, 5))

let parallel = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))
let above    = @type.Line::Line(@type.Coord(0.0, 1.0), @type.Coord(10.0, 1.0))
@lib2d.intersects_line_line(parallel, above)   // false

let touching = @type.Line::Line(@type.Coord(10.0, 0.0), @type.Coord(20.0, 0.0))
@lib2d.intersects_line_line(parallel, touching)   // true (share endpoint (10, 0))
```

Tests in `intersects_test.mbt`:

- `intersects_line_line — touching endpoints`
- `intersects_line_line — crossing`
- `intersects_line_line — parallel non-overlapping`
- `intersects_line_line — collinear overlapping`
- `intersects_polygon_polygon — overlap / disjoint`
- `intersects_geometry dispatch`

Plus the bench `bench: line_intersection crossing` (which times the related `line_intersection.mbt` path).

## Why this is cheaper than `line_intersection`

`intersects_line_line` returns `Bool`. `line_intersection` returns the actual `LineIntersection?` result with the crossing coord. They share most of the work — but `intersects` can short-circuit as soon as the four orientation signs are determined, while `line_intersection` always completes the parametric solve. For "did anything hit?" queries, prefer `intersects_*`.

## `intersects_geometry` dispatch

For a uniform call site, `intersects_geometry(a, b)` pattern-matches on both arguments and delegates to the appropriate per-pair function. **It is symmetric**: `intersects_geometry(a, b) == intersects_geometry(b, a)`, even though the per-pair functions may have ordered argument lists.

## Edge cases

- **Empty geometries** never intersect anything (no points to share).
- **Touching at a single boundary point** ⇒ `true` ("intersect" = share any point, including boundary).
- **Coincident segments** ⇒ `true` (they share infinitely many points).

## Performance

- `coord vs coord/line/rect`: `O(1)`.
- `coord vs line string / polygon`: `O(n)` — segment scan or ray casting.
- `line string vs line string`: `O(n × m)` naive segment-pair test. The port currently uses this naive scan; a sweep-line algorithm would bring it to `O((n+m+k) log (n+m))` but is post-scope.
- `polygon vs polygon`: `O(n × m)` worst case, but the bbox early-out makes the common case `O(1)`.

## Related

- `line_intersection.mbt` — actually computes the crossing point.
- `coordinate_position.mbt` — the underlying point-vs-region classifier.
- `contains.mbt`, `within.mbt`, `covers.mbt` — relations strictly stronger than `intersects`.

# `line_intersection.mbt` — exact crossing point of two segments

## Goal

Compute **where** two `Line` segments cross. The cheaper "do they cross at all?" decision-only sibling lives in `intersects.mbt`; this file produces an actual coordinate (or a coincident sub-segment, in the collinear case).

Used by sweep-line algorithms, polygon-polygon intersection (boolean ops), polyline self-intersection detection, and rendering pipelines that need to clip lines against shapes.

## API surface

```moonbit nocheck
pub(all) enum LineIntersection {
  // The two segments meet at a single point. The Bool flag is `true` for a
  // proper intersection (interior of both segments) and `false` for an
  // intersection at one of the four endpoints.
  SinglePoint(Coord, Bool)
  // The two segments are collinear and overlap on a sub-segment. The Line
  // describes that overlap segment.
  Collinear(Line)
}

pub fn line_intersection(p : Line, q : Line) -> LineIntersection?
```

`None` is returned when the segments are disjoint (parallel and non-overlapping, or skew with no crossing).

## Algorithm — non-collinear case

Given segments `p = (p₁, p₂)` and `q = (q₁, q₂)`:

1. Compute the four orientations:

   ```
   o1 = orient(p1, p2, q1)    o2 = orient(p1, p2, q2)
   o3 = orient(q1, q2, p1)    o4 = orient(q1, q2, p2)
   ```

   These come from `kernel.mbt` and are robust.

2. **Cross check**: `o1 ≠ o2` AND `o3 ≠ o4` ⇒ the segments cross properly. Compute the intersection coord by parametric solve:

   ```
   p(t) = p1 + t · (p2 − p1)
   q(s) = q1 + s · (q2 − q1)

   Solve p(t) = q(s):
     t = wedge(q1 − p1, q2 − q1) / wedge(p2 − p1, q2 − q1)

   intersection = p1 + t · (p2 − p1)
   ```

   The returned `SinglePoint(coord, true)` has `Bool = true` (proper intersection — both segments' interiors contributed).

3. **Endpoint coincidence**: at least one `oᵢ == Collinear` while the other side's orientations disagree ⇒ one segment's endpoint lies on the other segment. The coord is that endpoint, and the result is `SinglePoint(coord, false)` (improper intersection — boundary touching, not crossing).

## Algorithm — collinear case

If both pairs `(o1, o2)` and `(o3, o4)` have `Collinear` (i.e. all four points lie on the same line), the segments are collinear. They either:

- **Don't overlap** (disjoint sub-intervals on the same line) ⇒ `None`.
- **Overlap on a sub-segment** ⇒ project both segments onto the shared line's parameter axis, intersect the resulting 1-D intervals, and return `Collinear(Line(...))` with the endpoints of the overlap.

The overlap can degenerate to a single point (segments meet at exactly one endpoint along the shared line) — in that case the port returns `SinglePoint(coord, false)` rather than a zero-length collinear segment, for consistent downstream handling.

## The `Bool` flag in `SinglePoint`

```
SinglePoint(coord, true)   ⇒ proper:   coord is in the interior of both segments
SinglePoint(coord, false)  ⇒ improper: coord is at the endpoint of at least one segment
                                       (T-junctions and end-to-end touches)
```

This distinction matters for **sweep-line / planar subdivision** algorithms, where proper crossings split a segment into two new arcs, but improper touches don't change the topology of either segment.

## Examples

```moonbit nocheck
// Classic crossing
let l1 = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0))
let l2 = @type.Line::Line(@type.Coord(0.0, 10.0), @type.Coord(10.0, 0.0))
@lib2d.line_intersection(l1, l2)
//   Some(SinglePoint(Coord(5, 5), true))

// Endpoint touch (T-junction)
let l3 = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))
let l4 = @type.Line::Line(@type.Coord(5.0, 0.0), @type.Coord(5.0, 5.0))
@lib2d.line_intersection(l3, l4)
//   Some(SinglePoint(Coord(5, 0), false))     // improper — l3's interior, l4's endpoint

// Parallel non-overlapping
let l5 = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))
let l6 = @type.Line::Line(@type.Coord(0.0, 1.0), @type.Coord(10.0, 1.0))
@lib2d.line_intersection(l5, l6)            // None

// Collinear overlap
let l7 = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(5.0, 0.0))
let l8 = @type.Line::Line(@type.Coord(3.0, 0.0), @type.Coord(8.0, 0.0))
@lib2d.line_intersection(l7, l8)
//   Some(Collinear(Line(Coord(3, 0), Coord(5, 0))))
```

Tests in `line_intersection_test.mbt`:

- `line_intersection: classic crossing`
- `line_intersection: parallel non-overlapping`
- `line_intersection: collinear overlapping`

Plus the bench `bench: line_intersection crossing`.

## Robustness

The orientation determination uses the robust `kernel.mbt` predicate, so segments that are almost-parallel but not quite are correctly classified as crossing or non-crossing without sign flips. The numeric solve for `t` is non-robust (uses plain `f64` arithmetic), but its result is only used to compute the coord; small errors there manifest as a small position error in the returned coord, not a structural classification flip.

## Edge cases

- **Zero-length segments** (degenerate `Line` with `start == end`): treated as a point. Falls into the endpoint-coincidence path if it lies on the other segment, otherwise `None`.
- **Identical segments**: returns `Collinear(input)` — the entire segment is the overlap.
- **Both endpoints coincide**: `SinglePoint(coord, false)`.

## Performance

Constant time. Five orientation checks plus one solve. No allocation.

## Related

- `intersects.mbt` — `intersects_line_line` returns `Bool` only, ~25 % faster.
- `closest_point.mbt` — for the _closest_ point on a single segment to a target (not for two-segment crossing).
- `kernel.mbt` — the robust orientation predicate that powers the sign tests.
- `bool_ops.mbt` (Sutherland–Hodgman) — uses `line_intersection` to compute clipped polygon edges.

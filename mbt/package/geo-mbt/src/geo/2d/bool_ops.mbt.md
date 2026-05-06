# `bool_ops.mbt` — polygon clipping (Sutherland–Hodgman)

## Goal

Compute the **intersection** of one polygon (the *subject*) with another, simpler polygon (the *clip*). The output is a new polygon containing only the parts of the subject that lie inside the clip.

This is a **convex-clip-only** subset of polygon boolean operations. Full boolean ops (union / difference / xor / arbitrary subject vs. clip) are explicitly **out of scope** for this port — see `mbt/package/geo-mbt/CLAUDE.md`. Use this when you need:

- A polygon clipped to a viewport / bounding rect.
- A polygon clipped against a convex region (e.g. a country's bounding triangle).
- The general pattern "show me the parts of this shape inside that shape" where the latter is convex.

## API surface

```moonbit nocheck
pub fn intersection_polygon_rect(subject : Polygon, clip : Rect) -> Polygon
pub fn intersection_sutherland_hodgman(subject : Polygon, clip : Polygon) -> Polygon
```

The `_rect` form is a convenience wrapper that converts the rect to a 4-edge convex polygon and dispatches to `intersection_sutherland_hodgman`.

The clip polygon **must be convex**. Behaviour is undefined for non-convex clips — the algorithm doesn't detect or correct for it.

## Algorithm — Sutherland–Hodgman polygon clipping

The classic 1974 algorithm. Treats the **clip polygon as a sequence of half-planes** (one per edge) and clips the subject progressively against each:

```
output = subject.exterior().coords()      # start with the subject's coords

for each edge (cp, cq) of the clip polygon:
  input = output
  output = []

  for each consecutive pair (s, e) in input:
    cp_inside = (e is on the inside half-plane of cp→cq edge)
    s_inside  = (s is on the inside half-plane of cp→cq edge)

    if cp_inside:
      if not s_inside:
        emit intersection(s, e, cp, cq)     # entering: emit the crossing
      emit e                                 # always emit the inside endpoint
    else if s_inside:
      emit intersection(s, e, cp, cq)       # exiting: emit the crossing only

  # output now equals subject ∩ (half-plane of this edge)
```

After processing all clip edges, `output` is the intersection polygon's coord array.

The "inside half-plane" test is one orient call per edge endpoint. For a CCW-oriented convex clip polygon, "inside" means "to the left of the edge".

## Step-by-step (square clipped by a triangle)

```
subject:  4-coord square                 clip:  3-coord triangle
                                                       •
   ┌───────┐                                          ╱ ╲
   │       │                                         ╱   ╲
   │       │                                        ╱     ╲
   └───────┘                                       •───────•

Iteration 1: clip against triangle's first edge (the bottom).
   Both lower corners of the square are below the bottom edge → outside.
   Both upper corners are above → inside. The square's left and right sides
   each cross the bottom edge once.
   output: 4 coords (2 from upper corners, 2 from edge crossings)

Iteration 2: clip against the second edge (left side of triangle).
   Some of the previous output is still inside this half-plane, some isn't.
   The output gets clipped further.

Iteration 3: clip against the third edge.
   Final output: the polygon that's inside all three half-planes simultaneously.
```

Each iteration may add or remove vertices. The final output has at most `(subject_n + clip_m)` coords.

## Why the clip must be convex

Each step of Sutherland–Hodgman intersects the subject with a single half-plane (one edge of the clip extended infinitely). For a convex clip, the intersection of all those half-planes is exactly the clip's interior — perfect.

For a **non-convex** clip, the half-plane intersections overshoot. The algorithm produces output that's "inside the clip's convex hull but not necessarily inside the clip itself", which is geometrically wrong. Worse: re-entrant pieces of the subject (pieces that cross the clip's boundary multiple times) can produce spurious connecting segments.

A general boolean op (union / difference / arbitrary subject vs. clip) needs a different algorithm: Vatti, Greiner–Hormann, or DCEL-based intersection (e.g. the `i_overlay` crate that upstream `geo` uses for its `BooleanOps` trait). Those are deferred in this port.

## Examples

```moonbit nocheck
// Clip a polygon to a rect viewport
let polygon = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [],
)
let viewport = @type.Rect::Rect(@type.Coord(2.0, 2.0), @type.Coord(8.0, 8.0))
let clipped = @lib2d.intersection_polygon_rect(polygon, viewport)
// clipped's exterior == [(2,2), (8,2), (8,8), (2,8), (2,2)] — the inner square

// Disjoint case
let disjoint_rect = @type.Rect::Rect(@type.Coord(20.0, 20.0), @type.Coord(30.0, 30.0))
@lib2d.intersection_polygon_rect(polygon, disjoint_rect)
//   empty polygon (no coords)
```

Tests in `bool_ops_test.mbt`:

- `intersection_polygon_rect: subject fully inside clip`
- `intersection_polygon_rect: clip entirely inside subject`
- `intersection_polygon_rect: half overlap`
- `intersection_polygon_rect: disjoint`
- `intersection_sutherland_hodgman: triangle clipped by triangle`

## Edge cases

- **Empty subject or empty clip**: empty result.
- **Subject fully inside clip**: result is structurally equal to the subject.
- **Clip fully inside subject**: result is structurally equal to the clip (the algorithm clips the subject down to the clip's outline).
- **Disjoint subject and clip**: result is an empty polygon.
- **Non-convex clip**: undefined behaviour. The port doesn't currently detect this; callers must pre-validate via `is_convex(clip.exterior())`.
- **Polygons with holes**: Sutherland–Hodgman doesn't handle holes well — the output is **the exterior intersected with the clip**, with the input's holes not reflected in the output. For holed inputs, the result is approximate.

## Performance

`O(n_subject · m_clip)`. For typical clipping (clip is a rect, m = 4), this is essentially `O(n_subject)`.

## Related

- `intersects.mbt` — for "do they overlap at all?" without computing the intersection geometry.
- `is_convex.mbt` — pre-flight check to confirm the clip is convex.
- Future scope: full polygon boolean ops (union / difference / xor) would live in their own files (`union_polygon`, etc.) and use a different algorithm.

# `contains.mbt` — does `A` strictly contain `B`?

## Goal

Decide whether geometry `A` **strictly contains** geometry `B`: every point of `B` is either inside `A`'s interior, **and** at least one point of `B` is in `A`'s interior (not just on the boundary). This is the OGC SFA `Contains` predicate.

The port also implements the asymmetric companion `Within` (`B within A` ⇔ `A contains B`) and the boundary-inclusive `Covers` (which differs from `Contains` only at the boundary).

## API surface

```moonbit nocheck
pub fn contains_polygon_point(p, q)             -> Bool
pub fn contains_polygon_coord(p, c)             -> Bool
pub fn contains_polygon_line(p, l)              -> Bool
pub fn contains_polygon_line_string(p, ls)      -> Bool
pub fn contains_polygon_polygon(a, b)           -> Bool
pub fn contains_multi_polygon_coord(mp, c)      -> Bool
pub fn contains_rect_coord(r, c)                -> Bool
pub fn contains_rect_rect(a, b)                 -> Bool
pub fn contains_geometry(a, b)                  -> Bool   // dispatch
pub fn within_geometry(a, b)                    -> Bool   // == contains_geometry(b, a)
```

## The boundary subtlety: `contains` vs `covers`

Two pairs of definitions differ **only at the boundary**:

| Predicate     | A point of `B` on `A`'s boundary | A point of `B` inside `A`'s interior | At least one interior-interior overlap required? |
| ------------- | -------------------------------- | ------------------------------------- | ----------------------------------------------- |
| `contains`    | Allowed only if other points are inside; **boundary alone is not enough** | Required (at least one such point)     | Yes |
| `covers`      | Allowed                          | Not required                           | No                                              |

In particular:

```
poly:        ┌─────┐
             │     │
             │     │
             └─────┘

point on boundary of poly:
  contains_polygon_point(poly, pt)  →  false   (interior overlap required, but pt has no interior)
  covers_polygon_point(poly, pt)    →  true    (every part of pt is in poly's closure)

point strictly inside poly:
  contains_polygon_point(poly, pt)  →  true
  covers_polygon_point(poly, pt)    →  true
```

Use `contains` when you mean strict topological containment (e.g. "is this town fully inside the county and not on its border?") and `covers` when you mean weak containment (e.g. "would I see this point on the map if I drew the polygon?").

## Algorithm strategies

### `contains_polygon_coord` (point-in-polygon, strict)

```
1. coord_position_for_polygon(c, polygon)
2. result == Inside   → true
   result == OnBoundary or Outside → false
```

Strict boundary exclusion. Equivalent to "covers AND not OnBoundary".

### `contains_polygon_polygon`

```
1. bbox(B) inside bbox(A)? if no → false
2. every vertex of B inside A's interior or on A's boundary? if any vertex outside → false
3. no edge of B crosses any edge of A's exterior or interior rings? if any cross → false
4. at least one vertex of B strictly inside A? if all on boundary → false
                                                  (would be `equals`, not `contains`)
```

Step 4 is the "strict" requirement. If all of `B` lies on `A`'s boundary, they are equal-or-overlapping in 1-D and `contains` is false (use `covers` instead).

### `contains_polygon_line` / `contains_polygon_line_string`

Same shape: every coord of `line` / `line string` must be in `A`'s interior or on its boundary, AND no segment of the input crosses `A`'s boundary.

### `contains_rect_*`

Trivial bounding-box comparisons. `contains_rect_rect(a, b)` ⇔ `a.min.x ≤ b.min.x` AND `a.max.x ≥ b.max.x` AND analogously for `y`, with strict inequalities for "strict" containment of corner-coincident rects.

## `within_geometry` and `contains_geometry`

Symmetry: `within_geometry(a, b) ≡ contains_geometry(b, a)`. The port implements `within_geometry` as a one-line call to `contains_geometry` with arguments swapped.

`contains_geometry` pattern-matches on the **container** type first (which carries the dimension signal — only 2-D types can contain anything 2-D-ish meaningfully) and then on the contained type, dispatching to the right per-pair function.

## Examples

```moonbit nocheck
let outer = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [],
)
let inner = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(2.0, 2.0), (5.0, 2.0), (5.0, 5.0), (2.0, 5.0)]),
  [],
)

@lib2d.contains_polygon_polygon(outer, inner)     // true (inner strictly inside outer)
@lib2d.within_geometry(
  @type.Geometry::Polygon(inner),
  @type.Geometry::Polygon(outer),
)                                                 // true (same fact, reverse direction)

let pt_inside  = @type.Point::Point(5.0, 5.0)
let pt_on_edge = @type.Point::Point(0.0, 5.0)

@lib2d.contains_polygon_point(outer, pt_inside)   // true
@lib2d.contains_polygon_point(outer, pt_on_edge)  // false (boundary, not interior)
@lib2d.covers_polygon_point(outer, pt_on_edge)    // true  (covers includes boundary)
```

Tests in `contains_test.mbt`:

- `contains_polygon_point: inside / boundary excluded / outside`
- `covers_polygon_point: boundary INCLUDED`
- `contains_polygon_polygon: nested / not contained`
- `contains_rect_rect`
- `within is the inverse of contains`
- `covers_geometry boundary point`

Plus the bench `bench: contains_polygon_coord n=100`.

## Performance

`contains_polygon_coord` is `O(n)` (ray cast). `contains_polygon_polygon` is `O(n × m)` worst case but commonly `O(1)` thanks to the bbox early-out at step 1.

## Related

- `coordinate_position.mbt` — the underlying classifier.
- `covers.mbt` — boundary-inclusive sibling.
- `intersects.mbt` — symmetric "share any point" weaker relation.
- `within.mbt` — argument-flipped form (currently inlined into `within_geometry` in this same file's neighbourhood, but conceptually the same operation).

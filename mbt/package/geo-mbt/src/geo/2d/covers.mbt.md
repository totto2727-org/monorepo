# `covers.mbt` — does `A` cover `B` (boundary-inclusive containment)?

## Goal

Decide whether geometry `A` **covers** geometry `B`: every point of `B` lies in `A`'s closure (interior **or** boundary). This is the OGC SFA `Covers` predicate.

`covers` is the boundary-inclusive sibling of `contains`. They differ only when `B` has parts on `A`'s boundary — see the table in `contains.mbt.md` for the full breakdown.

## API surface

```moonbit nocheck
pub fn covers_polygon_point(p, q)         -> Bool
pub fn covers_polygon_coord(p, c)         -> Bool
pub fn covers_polygon_line_string(p, ls)  -> Bool
pub fn covers_polygon_polygon(a, b)       -> Bool
pub fn covers_rect_coord(r, c)            -> Bool
pub fn covers_geometry(a, b)              -> Bool   // dispatch
```

## How `covers` differs from `contains`

| Pair                                                | `contains` | `covers`  |
| --------------------------------------------------- | ---------- | --------- |
| Polygon / point strictly inside polygon             | true       | true      |
| Polygon / point exactly on polygon's boundary       | **false**  | **true**  |
| Polygon / smaller polygon strictly inside           | true       | true      |
| Polygon / smaller polygon sharing one boundary edge | **false**  | **true**  |
| Polygon / coincident polygon                        | false      | true      |

The rule:

```
A covers B  ⇔  no point of B lies outside A.
A contains B  ⇔  A covers B  AND  at least one point of B is in A's interior.
```

`covers` is the predicate you almost always want for *spatial filtering* ("is this feature inside the query rectangle, including features on the boundary?"). `contains` is the predicate you want for *strict topological reasoning* (DE-9IM, OGC compliance).

## Algorithm

Same shape as `contains` but with the boundary check **inclusive**:

### `covers_polygon_coord`

```
coord_position_for_polygon(c, p)  in  {Inside, OnBoundary}  →  true
coord_position_for_polygon(c, p)  == Outside                →  false
```

### `covers_polygon_polygon`

```
1. bbox(B) inside bbox(A)?      if no → false
2. every vertex of B in A's interior or boundary?  if any outside → false
3. no edge of B crosses any edge of A's interior?  if any cross  → false   (proper crossing, not touching)
   (touching at a coincident segment is allowed by `covers`)
```

The difference vs. `contains`: step 4 of `contains` (require at least one strict-interior overlap) is **dropped**. A polygon can cover an identical polygon — they share the same boundary and have no points outside each other.

### `covers_rect_coord`

`r.min.x ≤ c.x ≤ r.max.x` AND `r.min.y ≤ c.y ≤ r.max.y` (both inclusive).

## Examples

```moonbit nocheck
let outer = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [],
)

let pt_corner = @type.Point::Point(0.0, 0.0)   // on boundary
let pt_inside = @type.Point::Point(5.0, 5.0)
let pt_outside = @type.Point::Point(15.0, 5.0)

@lib2d.covers_polygon_point(outer, pt_corner)    // true
@lib2d.contains_polygon_point(outer, pt_corner)  // false  (boundary excluded)

@lib2d.covers_polygon_point(outer, pt_inside)    // true
@lib2d.covers_polygon_point(outer, pt_outside)   // false
```

Tests in `covers_test.mbt`:

- `covers_polygon_point: boundary INCLUDED`
- `covers_geometry boundary point`

## Trade-offs

- `covers` is sometimes the safer default because it doesn't have edge-case false negatives at boundaries (which would surprise users querying "is this on the map?").
- `contains` is required when you need DE-9IM strictness (e.g. "this small polygon is strictly inside the bigger one with no shared edge").

## Performance

Same complexity as `contains`. `O(n)` for point-in-polygon, `O(n × m)` for polygon-polygon. The bbox early-out is the dominant optimisation in practice.

## Related

- `contains.mbt` — strict sibling.
- `coordinate_position.mbt` — the underlying classifier (returns `Inside` / `OnBoundary` / `Outside`, which is exactly what these predicates project down to a `Bool`).

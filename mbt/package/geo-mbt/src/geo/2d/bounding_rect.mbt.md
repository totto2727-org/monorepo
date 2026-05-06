# `bounding_rect.mbt` — axis-aligned bounding box (AABB)

## Goal

Find the **smallest axis-aligned rectangle** that fully contains a geometry. Used everywhere as a cheap "first-line filter" — many geometric tests (`intersects`, `contains`, spatial indexing in `rtree`) can return early with a bbox-vs-bbox check before doing the expensive shape-vs-shape comparison.

## API surface

| Function                                   | Result  | Empty input                                 |
| ------------------------------------------ | ------- | ------------------------------------------- |
| `bounding_rect_of_coord(c)`                | `Rect`  | n/a (a coord is never empty)                |
| `bounding_rect_of_point(p)`                | `Rect`  | n/a — degenerate `Rect` with `min == max`   |
| `bounding_rect_of_line(l)`                 | `Rect`  | n/a                                         |
| `bounding_rect_of_line_string(ls)`         | `Rect?` | `None` when `ls` has 0 coords               |
| `bounding_rect_of_polygon(p)`              | `Rect?` | `None` when exterior is empty               |
| `bounding_rect_of_multi_*`                 | `Rect?` | `None` when no member contributes any point |
| `bounding_rect_of_geometry(g)`             | `Rect?` | Dispatch over `Geometry` enum               |
| `bounding_rect_of_geometry_collection(gc)` | `Rect?` | `None` when collection is empty             |
| `bounding_rect_of_rect(r)`                 | `Rect`  | The rect itself (identity)                  |
| `bounding_rect_of_triangle(t)`             | `Rect`  | Always defined (3 finite vertices)          |

The `Rect?` return form (instead of `Rect`) is the port's way of signalling "the geometry contributed no points, so the bounding rectangle is undefined". This is structurally cleaner than upstream's "empty" sentinel `Rect`.

## Algorithm

Trivial:

1. Walk every coordinate the geometry exposes (via `CoordsCarrier::coords` for the homogeneous types, or the underlying ring coords for `Polygon`).
2. Track running `(min_x, min_y, max_x, max_y)` initialised from the first coord.
3. For each subsequent coord, `min_x = min(min_x, c.x)`, etc.
4. Return `Rect(Coord(min_x, min_y), Coord(max_x, max_y))`.

For composite types (`MultiPolygon`, `GeometryCollection`), the algorithm recurses into each member's bounding rect and then takes the bbox of bboxes. `None`-valued members are skipped so an empty member doesn't poison the result.

## Step-by-step (line string)

```
input:  LineString [(2, 1), (5, 4), (3, 7), (0, 3)]

start:  min_x = 2, max_x = 2, min_y = 1, max_y = 1   (from coord 0)
coord 1: (5, 4) →   min_x = 2, max_x = 5, min_y = 1, max_y = 4
coord 2: (3, 7) →   min_x = 2, max_x = 5, min_y = 1, max_y = 7
coord 3: (0, 3) →   min_x = 0, max_x = 5, min_y = 1, max_y = 7

result: Rect(Coord(0, 1), Coord(5, 7))
```

The Trait API on the port (`Bounded::bbox(self) -> Rect?`) has a uniform impl per type that wraps these free functions.

## Why the special `coord` / `point` / `line` / `triangle` / `rect` cases

These types are **never** empty by construction (they always have at least one finite vertex), so they return `Rect` directly without the `Option` wrapper. The compile-time guarantee saves callers from `unwrap()`s.

A `Point` produces a degenerate `Rect` with `min == max` — this is intentional and matches OGC SFA (a point has zero width and zero height).

## Examples

```moonbit nocheck
///|
let ls = @type.LineString::from_tuples([(2.0, 1.0), (5.0, 4.0), (0.0, 3.0)])

///|
let bbox = @lib2d.bounding_rect_of_line_string(ls).unwrap()
// bbox.min == Coord(0, 1), bbox.max == Coord(5, 4)
// bbox.width()  == 5, bbox.height() == 3
```

For empty input:

```moonbit nocheck
let empty_ls = @type.LineString::empty()
@lib2d.bounding_rect_of_line_string(empty_ls)   // None
```

See `bounding_rect_test.mbt`:

- `bounding_rect_of_line_string`
- `bounding_rect_of_point is degenerate`
- `bounding_rect_of_line_string empty`

And the property test `property: bounding rect contains every coord of the geometry` (`property_test.mbt`).

## Performance

`O(n)`. Single pass over all coords, no allocation. Benchmarked as `bench: bounding_rect_of_line_string n=100` (`bounding_rect_bench_test.mbt`).

## Caveats

- Floating-point only: `min` / `max` propagate `NaN` if any coord is `NaN`. Use `validation.mbt`'s `is_valid` upstream of bbox calls if your data may contain non-finite values.
- The bbox is only as tight as the input vertices — a curve approximated by few line segments will produce a bbox slightly larger than the true geometric extent.

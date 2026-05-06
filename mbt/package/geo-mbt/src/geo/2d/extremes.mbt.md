# `extremes.mbt` — extreme coordinates of a geometry

## Goal

Pick out the **four extreme points** of a geometry — the actual coords (not just the bounding box corners) that touch the bounding rectangle's edges.

For a polygon, these are the leftmost, rightmost, topmost, and bottommost vertices. They're the **vertices that would touch a pair of vertical and horizontal calipers** sweeping in from infinity.

This is what you want when you're asking "give me a representative landmark on each side of this shape". It's distinct from:

- `bounding_rect_of_*` — gives you four `Coord`s computed by `min` / `max` aggregation; those *are not* vertices of the input.
- `convex_hull_of_*` — gives you the full hull polygon (more vertices, more cost).

## API surface

```moonbit nocheck
pub(all) struct Outcome {
  x_min : Coord    // vertex with the smallest x
  x_max : Coord    // vertex with the largest  x
  y_min : Coord    // vertex with the smallest y
  y_max : Coord    // vertex with the largest  y
}

pub fn extremes_of_coords(coords : Array[Coord]) -> Outcome?
pub fn extremes_of_geometry(g : Geometry)        -> Outcome?
```

`None` is returned for empty inputs (no coords to pick extremes from).

## Algorithm

Trivial:

1. Walk every coord the geometry exposes.
2. Track running `(x_min_coord, x_max_coord, y_min_coord, y_max_coord)`, initialised from the first coord.
3. For each subsequent coord, replace any of the four if it strictly improves the corresponding extreme.

The result holds **actual vertices of the input**, not synthetic `Coord`s assembled from `min` / `max` of `x` / `y` independently.

```
input: 5 vertices

  •(2,8)         ← y_max
        •(7,5)   ← x_max
   •(0,3)        ← x_min
        •(6,1)   ← y_min
            •(4,4)
```

The bounding box (from `bounding_rect_of_coords`) would be `Rect((0,1), (7,8))` — its four corners are synthetic. The extremes here are the four real vertices `(0,3) (7,5) (6,1) (2,8)`.

## Tie-breaking

When multiple coords share the same extreme value, the **first one encountered** in iteration order wins. This is consistent across calls (the iteration order is the geometry's internal coord order — exterior ring first, then interiors, then sub-geometries).

## Examples

```moonbit nocheck
///|
let coords = [
  @type.Coord(2.0, 8.0),
  @type.Coord(7.0, 5.0),
  @type.Coord(0.0, 3.0),
  @type.Coord(6.0, 1.0),
  @type.Coord(4.0, 4.0),
]

///|
let r = @lib2d.extremes_of_coords(coords).unwrap()
// r.x_min == Coord(0, 3)
// r.x_max == Coord(7, 5)
// r.y_min == Coord(6, 1)
// r.y_max == Coord(2, 8)
```

Tests in `extremes_test.mbt`:

- `extremes_of_geometry`

## Use cases

- Initial guess for a **convex hull** — three of the four extreme points are guaranteed to be on the hull (rotating-callipers warm start).
- **Anchor points** for labelling a polygon (e.g. "leftmost vertex" for an arrow).
- Quick sanity check that a geometry "looks like" what you expect (extremes are easier to reason about than centroid).

## Edge cases

- **Single coord** → all four extremes are that coord.
- **Empty input** → `None`.
- **Degenerate inputs** (e.g. all coords on a vertical line) — `x_min` and `x_max` may equal the same coord; the four fields are independent.

## Performance

`O(n)`, single pass, no allocation. Faster than `convex_hull_of_*` by about an order of magnitude (no sort, no orientation tests) — useful when you only need a quick anchor and not the full hull.

## Upstream parity

In Rust upstream `geo`, `extremes::Extreme<T>` carries both the index *and* the coord; the port keeps only the coord because indexing into a heterogeneous `Geometry` tree isn't useful when the input may be a `MultiPolygon`. If you need the index for a flat input, walk `coords` yourself with `Array::iter().enumerate()`.

# `winding_order.mbt` — CCW or CW?

## Goal

Decide whether the coordinates of a closed ring (a `LineString` whose first coord equals its last) wind around the ring's interior **counter-clockwise** or **clockwise**, and provide a helper to **reverse** a line string.

Winding order matters because:

- OGC SFA / GeoJSON specify that polygon **exterior** rings should be CCW and **interior** rings (holes) should be CW (or vice versa, depending on the spec — but always opposite).
- Many algorithms in this port assume a particular winding when interpreting a polygon — `bool_ops.mbt` clipping, signed-area computation for centroid, etc.
- `convex_hull` produces a result in known CCW order so downstream consumers don't have to query.

The port doesn't enforce winding at construction time (see the api-correspondence.md note on §1.4 / §1.5). Algorithms that need a particular winding query / fix it explicitly via this file's helpers.

## API surface

```moonbit nocheck
pub(all) enum WindingOrder {
  Clockwise
  CounterClockwise
}

pub fn winding_order(ls : LineString) -> WindingOrder?
pub fn reverse_line_string(ls : LineString) -> LineString
```

`winding_order` returns `None` for inputs that don't have a meaningful winding:

- Empty line string
- Fewer than 3 distinct coords (a degenerate ring has zero signed area, no orientation)

## Algorithm

The implementation uses **`twice_signed_ring_area(ls)`** from `area.mbt` (which itself uses the shoelace formula plus robust kernel for the triangle terms):

```
twice_area = twice_signed_ring_area(ls)

if twice_area > 0  →  CounterClockwise
if twice_area < 0  →  Clockwise
if twice_area == 0 →  None   (degenerate)
```

Recall that the shoelace formula returns a positive value for CCW rings and a negative value for CW rings — this is the same fact that powers `signed_area_of_polygon`. `winding_order` projects that signed value down to the enum.

## `reverse_line_string`

Returns a new `LineString` whose coords are in reverse order. Pure / non-mutating (per `coding/mbt-bestpractice.md` §3.12).

```
input:   LineString [a, b, c, d, a]   (closed, CCW)
output:  LineString [a, d, c, b, a]   (closed, CW)
```

The first coord is preserved as the first coord (so a closed ring stays closed). The orientation flips because the traversal direction flips.

## Examples

```moonbit nocheck
let ccw = @type.LineString::from_tuples([
  (0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0),
])
@lib2d.winding_order(ccw)                  // Some(CounterClockwise)

let cw = @lib2d.reverse_line_string(ccw)
@lib2d.winding_order(cw)                   // Some(Clockwise)

let degen = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (0.0, 0.0)])
@lib2d.winding_order(degen)                // None (collinear, signed area = 0)
```

Tests in `winding_order_test.mbt`:

- `winding_order: CCW positive area`
- `winding_order: CW negative area`
- `reverse_line_string`

Property test (`property_test.mbt`):

- `property: signed_area flips sign when coords are reversed` — exercises the round-trip `winding_order ∘ reverse` ↔ `reverse ∘ winding_order`.

## Why `WindingOrder?` (Option) instead of "default to CCW"

A degenerate ring (zero signed area) has no winding direction — assigning a default would silently mask programming bugs. The port returns `None` and forces the caller to handle the degenerate case explicitly. Most algorithms that depend on winding (e.g. `orient_polygon`) treat `None` as a no-op.

## Caveats

- Inputs that are **not closed** (`coords[0] ≠ coords[-1]`) are treated as if they were — the formula still works algorithmically, but the result is the winding of the *implicit* closure. If your input might be open and you want to reject that, check `ls.is_closed()` first.
- **Self-intersecting rings** ("bowtie") have a well-defined signed area (half the difference of the lobe areas) but no meaningful winding — the value reflects a net signed area, not a topological winding direction. `validation.mbt`'s `SelfIntersection` problem catches these.

## Related

- `area.mbt` — the underlying signed-area machinery.
- `orient.mbt` — uses `winding_order` to drive its `orient_polygon(_, OrientDirection::Default | Reversed)` per-ring orientation enforcement.
- `is_convex.mbt` — orthogonal property: convexity is independent of winding direction.

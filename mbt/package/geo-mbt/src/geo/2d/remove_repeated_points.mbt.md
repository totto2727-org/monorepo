# `remove_repeated_points.mbt` — drop adjacent duplicate coords

## Goal

Remove **consecutive identical coordinates** from a line string or polygon ring. The output represents the same geometry but without zero-length edges.

This is the cleanest of the deduplicating operations: it doesn't merge nearby points, doesn't reorganise the polyline, doesn't simplify shape — it just removes vertices that are bit-for-bit equal to their predecessor.

Useful when:

- Input data has been concatenated from multiple segments and shares endpoints.
- A user accidentally clicks twice on the same location while digitising.
- A previous transformation may have introduced zero-length edges (e.g. a projection that maps two distinct lat/lon points to the same x/y).

## API surface

```moonbit nocheck
pub fn remove_repeated_points_line_string(ls : LineString) -> LineString
pub fn remove_repeated_points_polygon(p : Polygon) -> Polygon
```

## Algorithm

```
output = []
for each coord c in input.coords():
  if output is empty or c != last(output):
    push c

return new LineString(output)
```

Equality is **bit-exact** (`==` on `Coord`). Coordinates that are within floating-point epsilon of each other but not exactly equal are NOT removed. This is intentional: removing "nearby" coords is the job of `simplify.mbt` / `simplify_vw.mbt`, which take a tolerance parameter.

For a polygon, the same operation is applied independently to the exterior ring and every interior ring.

## What does NOT change

- The output preserves **order** — only adjacent duplicates are removed.
- Non-adjacent duplicates (`A, B, A`) are kept; the function only looks one step back.
- The first vertex is never removed; consequently a closed ring whose first and last coords are the same will keep both (since they're not adjacent — the ring goes through everything in between).

## Examples

```moonbit nocheck
// Adjacent duplicates removed
let ls = @type.LineString::from_tuples([
  (0.0, 0.0), (0.0, 0.0), (5.0, 0.0), (5.0, 0.0), (5.0, 5.0)
])
@lib2d.remove_repeated_points_line_string(ls).coords().length()
//   3 — kept [(0,0), (5,0), (5,5)]

// Non-adjacent duplicates kept
let ABA = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (0.0, 0.0)])
@lib2d.remove_repeated_points_line_string(ABA).coords().length()
//   3 — kept all (not adjacent)

// Closed ring with start == end: the closure is preserved
let ring = @type.LineString::from_tuples([
  (0.0, 0.0), (5.0, 0.0), (5.0, 5.0), (0.0, 5.0), (0.0, 0.0)
])
@lib2d.remove_repeated_points_line_string(ring).coords().length()
//   5 — closure (0,0) at the end is not adjacent to (0,0) at the start
```

Tests in `simplify_test.mbt`:

- `remove_repeated_points removes consecutive duplicates`

## Edge cases

- **Empty input**: returned unchanged (empty output).
- **All-identical input**: collapsed to a single coord.
- **Polygon with auto-closing duplicate**: the first and last coords of a closed ring are equal, but they're **not adjacent** in the array (everything in between is between them), so they're both kept. The auto-closing behaviour of `Polygon::Polygon` is preserved.

## Performance

`O(n)` single pass. The output is built via spread-literal accumulation:

```moonbit nocheck
let result = []
for c in input.coords() {
  if result.length() == 0 || result[result.length() - 1] != c {
    // (the implementation uses Array::makei or push depending on local owning)
  }
}
```

Per `coding/mbt-bestpractice.md`, the array is owned locally; the immutable view is rebuilt at the end via a fresh `LineString::LineString(...)`.

## Why bit-exact?

The function is meant to be a **structural** clean-up, not a metric one. If you have coords that are approximately equal due to floating-point drift, you have two options:

1. **Apply a numeric tolerance**: round all coords to a fixed number of decimal places before calling `remove_repeated_points`. This is application-specific.
2. **Use `simplify.mbt` instead**: with a small `epsilon`, it removes near-duplicates AND collinear-redundant points in one pass.

The port keeps `remove_repeated_points` strictly bit-exact so it has a precise, predictable definition.

## Related

- `simplify.mbt` / `simplify_vw.mbt` — for tolerance-based simplification.
- `validation.mbt` — `RingTooFewPoints` reports rings reduced to too few coords after dedup; useful as a safety check after simplification.

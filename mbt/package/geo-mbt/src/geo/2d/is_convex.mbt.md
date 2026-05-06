# `is_convex.mbt` — convexity check for a closed ring

## Goal

Decide whether the coordinates of a closed ring (e.g. `polygon.exterior()`) outline a **convex polygon**. A polygon is convex iff every internal angle is ≤ 180° — equivalently, walking around the ring you only ever turn the same direction (always left, or always right; never both).

## API surface

```moonbit nocheck
pub fn is_convex(ls : LineString) -> Bool
pub fn is_strictly_convex(ls : LineString) -> Bool
```

| Function             | Allows three consecutive collinear points?      |
| -------------------- | ----------------------------------------------- |
| `is_convex`          | Yes — collinear triples don't affect the result |
| `is_strictly_convex` | No — any collinear triple ⇒ false               |

`is_convex` is the OGC-style notion (a convex polygon may have redundant collinear vertices and still count). `is_strictly_convex` is the "strict math" notion (all interior angles < 180°, no degenerate vertices).

## Algorithm

```
1. Effective length: drop the last coord if it equals the first (working on
   a "closed view" without the closing duplicate). Need ≥ 3 effective coords.

2. Walk the ring as triples (i, i+1, i+2) modulo effective length.
   For each triple, compute orient(p, q, r) using kernel.orient (robust).

3. Track the sign:
     0 = unset
     +1 = the only sign seen so far is CCW
     -1 = the only sign seen so far is CW

   On each triple:
     - If orient is Collinear:
         * is_convex: ignore (continue)
         * is_strictly_convex: return false immediately
     - Otherwise, derive a sign (+1 for CCW, −1 for CW).
       If sign is unset: set it.
       If sign disagrees with the running sign: return false.

4. After visiting every triple: return true.
```

The intuition: a convex polygon is one where all the "turns" at each vertex go the same way. Any vertex that bends the opposite way creates a concavity, which the sign comparison catches immediately.

The use of `kernel.orient` (robust) is essential: a near-collinear concavity computed with naive `f64` arithmetic can flip-flop between Collinear and the wrong sign, producing wrong answers.

## Examples

```moonbit nocheck
// Regular pentagon: convex
let pentagon = @type.LineString::from_tuples([
  (1.0, 0.0), (0.31, 0.95), (-0.81, 0.59), (-0.81, -0.59), (0.31, -0.95), (1.0, 0.0)
])
@lib2d.is_convex(pentagon)             // true
@lib2d.is_strictly_convex(pentagon)    // true

// Star (concave): not convex
let star = @type.LineString::from_tuples([
  (0.0, 5.0), (1.0, 1.5), (5.0, 1.5), (1.5, -0.5), (3.0, -4.0),
  (0.0, -2.0), (-3.0, -4.0), (-1.5, -0.5), (-5.0, 1.5), (-1.0, 1.5), (0.0, 5.0)
])
@lib2d.is_convex(star)                 // false

// Square with a redundant midpoint vertex on one edge: convex (collinear allowed)
//   ...  (0,0), (5,0), (10,0), (10,10), (0,10), (0,0)  ← (5,0) is collinear with (0,0)→(10,0)
@lib2d.is_convex(square_with_midpoint)         // true
@lib2d.is_strictly_convex(square_with_midpoint) // false  (collinear triple)
```

Tests in `is_convex_test.mbt`:

- `is_convex: square`
- `is_convex: concave shape`

## What "ring" means

The function accepts a `LineString` because the input might come from `polygon.exterior()` or any closed ring. A `LineString` whose first coord doesn't equal its last is treated as if it did — the implicit closing edge counts as part of the ring.

To test a polygon's exterior, write `is_convex(polygon.exterior())`. Interior rings (holes) can also be tested individually if you care about their shape.

## Caveats

- **Self-intersecting "bowtie" rings**: the sign test sees consistent turns and may return `true` even though the shape isn't a real convex polygon. Run `validation.mbt`'s `is_valid` upstream to catch self-intersection.
- **Open polylines** (start ≠ end): treated as if closed. If your input might be open and that should fail, check `ls.is_closed()` first.
- **Two- or fewer-coord inputs**: return `false` (no triple to evaluate).
- **`Polygon::is_convex` is not exposed** — call `is_convex(polygon.exterior())` directly. Upstream `geo-types::Polygon::is_convex` is `#[deprecated]` for the same reason; see `api-correspondence.md` §1.5.

## Performance

`O(n)` — single pass over the ring. Each triple costs one `orient` call (one robust determinant). No allocation.

## Related

- `convex_hull.mbt` — for _computing_ the hull when a polygon isn't convex.
- `kernel.mbt` — the robust orient predicate.
- `winding_order.mbt` — orthogonal property: a polygon's winding (CCW vs CW) is independent of whether it's convex.

# `closest_point.mbt` — closest point on a line / line string to a target

## Goal

Given a target `Coord` and a line / line string, find the point on the line **nearest to the target**. The result is a `Closest` enum that distinguishes:

- **`Intersection(coord)`** — the target lies _exactly_ on the line (zero distance).
- **`SinglePoint(coord)`** — the target is off the line; this is the nearest point on the line.
- **`Indeterminate`** — the input is degenerate (e.g. an empty line string).

This is the foundation for `euclidean_distance_coord_to_line` (which discards the coord and keeps only the distance), as well as snap-to-feature operations in editing tools.

## API surface

```moonbit nocheck
pub(all) enum Closest {
  Intersection(Coord)
  SinglePoint(Coord)
  Indeterminate
}

pub fn closest_point_on_line(line : Line, target : Coord) -> Closest
pub fn closest_point_on_line_string(ls : LineString, target : Coord) -> Closest
```

## Algorithm — point on a line segment

Given segment `(a, b)` and target `c`:

1. Parametrise the segment as `a + t · (b − a)` with `t ∈ ℝ`.
2. Solve for the projection scalar:

   ```
   t* = ((c − a) · (b − a)) / |b − a|²
   ```

   This is the **dot-product projection** of the offset `(c − a)` onto the direction `(b − a)`, normalised by the squared segment length.

3. **Clamp** `t = clamp(t*, 0, 1)`. Without the clamp, the answer would be the foot of the perpendicular on the _infinite line_ — but we want the closest point on the _segment_, so we project to the nearer endpoint when `t* < 0` or `t* > 1`.

4. The closest point is `a + t · (b − a)`.

5. If `closest == c` (zero distance), return `Intersection(closest)`. Otherwise `SinglePoint(closest)`.

```
       •c
        ╲                  •c                       •c
         ╲                  │                        ╲
          ╲       a─●────b  a───●─────b      a────b   ●
   a───●──b           t=0.4         t=0.7      t past b
   t* < 0 →           foot inside        →     t clamps
   clamps to a        foot inside              to b
   (t = 0)            (t = clamped)            (t = 1)
```

## Algorithm — closest point on a line string

A line string has multiple segments. The closest point is the closest of any per-segment result:

```
1. For each segment s of the line string:
   c_i ← closest_point_on_line(s, target)
   d_i ← euclidean_distance_coords(target, c_i.coord)

2. Pick the (c_i, d_i) with the smallest d_i.

3. If d_i == 0 → return Intersection(c_i.coord).
   Otherwise   → return SinglePoint(c_i.coord).
```

Tied distances (target equidistant from two segments) — the **first** segment encountered wins. This is deterministic but the choice between equidistant candidates is arbitrary.

## Examples

```moonbit nocheck
let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))

@lib2d.closest_point_on_line(line, @type.Coord(5.0, 3.0))
//   foot is (5, 0)  → SinglePoint(Coord(5, 0))

@lib2d.closest_point_on_line(line, @type.Coord(15.0, 3.0))
//   foot would be (15, 0) but t > 1, clamps to endpoint (10, 0)
//   → SinglePoint(Coord(10, 0))

@lib2d.closest_point_on_line(line, @type.Coord(5.0, 0.0))
//   target is on the segment → Intersection(Coord(5, 0))
```

Tests in `closest_point_test.mbt`:

- `closest_point_on_line: midpoint`
- `closest_point_on_line: clamped to start`
- `closest_point_on_line: target on line`

## Why a 3-variant enum?

The distinction between `SinglePoint` and `Intersection` matters for:

- **Distance computations**: when distance is exactly zero, callers may want to short-circuit.
- **Snapping editors**: a "snap to vertex" UI behaves differently when the cursor is _on_ a vertex vs. _near_ one.
- **Symbolic algorithms**: 0 distance means the target was already on the geometry; positive distance means it wasn't.

`Indeterminate` is reserved for inputs where no answer is meaningful (empty line string).

## Caveats

- **Floating-point equality** for the `Intersection` check is exact (`closest == target`). In practice this is rarely true unless the target is itself an endpoint of a segment. Most "exactly on the line" cases will be reported as `SinglePoint(coord)` with very small distance instead.
- Returns the **first** match for ties.

## Performance

`closest_point_on_line`: `O(1)` — one dot product, one length, one clamp.

`closest_point_on_line_string`: `O(n)` — segment scan with constant work per segment. No allocation.

## Related

- `euclidean.mbt` — `euclidean_distance_coord_to_line` is the distance-only version of this.
- `line_locate_point.mbt` — returns the parametric `t` (in `[0, 1]`) instead of the coord.
- `line_interpolate_point.mbt` — the inverse: given `t`, return the coord.

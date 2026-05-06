# `line_locate_point.mbt` — parametric position of a coord on a line

## Goal

Given a target `Coord` and a line / line string, return how far along the line the **closest point on the line** lies, expressed as a value in `[0, 1]`:

- `0` ⇒ at the start
- `1` ⇒ at the end
- `0.5` ⇒ exactly half-way along
- in between ⇒ the corresponding fraction of the line's total length

This is the inverse of `line_interpolate_point` (which goes from `t` to a coord).

Useful for snapping a clicked point to a line and recording "the user clicked at 23 % of the way along this road", and for measuring distance-along-line in editing tools.

## API surface

```moonbit nocheck
pub fn line_locate_point(l : Line, target : Coord) -> Double?
pub fn line_string_locate_point(ls : LineString, target : Coord) -> Double?
```

`None` is returned when the line / line string is degenerate (zero length) — there's no meaningful parametrisation.

## Algorithm — single segment

Given segment `(a, b)` and target `c`:

1. Compute the projection scalar (same as `closest_point_on_line`):

   ```
   t* = ((c − a) · (b − a)) / |b − a|²
   ```

2. **Clamp** to `[0, 1]`. Targets whose foot falls outside the segment get clamped to the nearest endpoint.

3. Return the clamped `t`.

```
foot inside segment:
  •c                       a────●─────b           returns t = 0.4
   ╲
    ●                                              (40 % of the way along)
   ╱
  a────────────b

foot beyond start:
       •c                   ●──────────b           returns t = 0.0
        ╲                   a
         ●                                         (clamped to start)
        ╱
  a────────────b
```

## Algorithm — line string

A line string has multiple segments of varying length. `line_string_locate_point` returns the position **along the entire line string**, normalised to `[0, 1]`:

```
1. For each segment s of the line string:
   - foot_s ← closest_point_on_line(s, target)
   - distance_target_to_foot_s
   - cumulative_length_at_segment_start

2. Pick the segment with the smallest target-to-foot distance.

3. Within that segment, locate the foot's parametric position t_local ∈ [0, 1].

4. Convert to the global parameter:
     t_global = (cumulative_length_at_segment_start + t_local · segment_length)
                / total_line_string_length
```

So `0.5` on a 100-metre line string means "50 metres along", regardless of how many segments make up that 100 metres or how unevenly they're spaced.

## Examples

```moonbit nocheck
let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))

@lib2d.line_locate_point(line, @type.Coord(5.0, 3.0))   // Some(0.5)  — foot at midpoint
@lib2d.line_locate_point(line, @type.Coord(0.0, 3.0))   // Some(0.0)  — foot at start
@lib2d.line_locate_point(line, @type.Coord(15.0, 3.0))  // Some(1.0)  — clamped to end
@lib2d.line_locate_point(line, @type.Coord(5.0, 0.0))   // Some(0.5)  — exactly on segment

let degenerate = @type.Line::Line(@type.Coord(2.0, 2.0), @type.Coord(2.0, 2.0))
@lib2d.line_locate_point(degenerate, @type.Coord(5.0, 5.0))   // None
```

Tests in `line_locate_point_test.mbt`:

- `line_locate_point: midpoint of segment is 0.5`
- `line_locate_point: beyond end is clamped to 1.0`

Property test (`property_test.mbt`):

- `property: line_locate ∘ line_interpolate ≈ id` — round-trip identity for any `t ∈ [0, 1]`.

## Round-trip with `line_interpolate_point`

For any line / line string `L` and any `t ∈ [0, 1]`:

```
line_locate_point(L, line_interpolate_point(L, t)) ≈ t
```

This identity holds up to floating-point precision and is exercised by the property test above.

## Edge cases

- **Zero-length line / line string** (all coords coincident) ⇒ `None`.
- **Target equidistant from two segments** ⇒ the first segment encountered wins (same tie-breaking rule as `closest_point.mbt`).
- **Target equal to an endpoint** ⇒ `0.0` or `1.0` exactly.

## Performance

`line_locate_point`: `O(1)`.

`line_string_locate_point`: `O(n)` segment scan plus a constant `O(1)` re-walk to compute cumulative length. The implementation pre-computes the total length once.

## Related

- `line_interpolate_point.mbt` — the inverse map.
- `closest_point.mbt` — returns the coord of the foot rather than its parametric position.
- `euclidean.mbt` — for computing distances rather than parametric positions.

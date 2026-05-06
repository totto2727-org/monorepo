# `line_interpolate_point.mbt` — the coord at parametric position `t`

## Goal

Given a line / line string and a fraction `t ∈ [0, 1]`, return the **coord at `t · totalLength` along the line**. The inverse of `line_locate_point`.

Useful for placing labels at known fractions of a path, animating a marker along a route, generating evenly-spaced sample points along an isoline, and so on.

## API surface

```moonbit nocheck
pub fn line_interpolate_point(l : Line, t : Double) -> Point
pub fn line_string_interpolate_point(ls : LineString, t : Double) -> Point?
```

For a single segment `Line`, the result is always defined (a `Line` is never empty).

For a `LineString`, the result is `None` when the line string is empty (no coords) or has total length 0 (all coords coincident).

## Algorithm — single segment

Given segment `(a, b)` and fraction `t`:

```
result = a + t · (b − a)
```

The fraction is **clamped to `[0, 1]`** at the boundaries:

- `t ≤ 0` ⇒ returns `a` (the start).
- `t ≥ 1` ⇒ returns `b` (the end).

This is **linear interpolation** between the endpoints — the simplest possible curve parametrisation.

## Algorithm — line string

A line string has segments of varying lengths. `line_string_interpolate_point` interprets `t` as a fraction of the **total arc length**:

```
1. total = euclidean_length_line_string(ls)
2. target = clamp(t, 0, 1) · total
3. Walk segments accumulating length:
     For each segment s with length len_s:
       if accumulated + len_s >= target:
         t_local = (target − accumulated) / len_s
         return line_interpolate_point(s, t_local)
       accumulated += len_s
4. Edge case: t == 1 returns the final coord exactly (avoids floating-point drift).
```

So `t = 0.5` on a 100-metre line string returns the coord exactly 50 metres in, even if the line string has unevenly-spaced vertices.

## Examples

```moonbit nocheck
let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))

@lib2d.line_interpolate_point(line, 0.0)   // Point(0, 0)    — start
@lib2d.line_interpolate_point(line, 0.5)   // Point(5, 0)    — midpoint
@lib2d.line_interpolate_point(line, 1.0)   // Point(10, 0)   — end
@lib2d.line_interpolate_point(line, 1.5)   // Point(10, 0)   — clamped
@lib2d.line_interpolate_point(line, -0.2)  // Point(0, 0)    — clamped

let zigzag = @type.LineString::from_tuples([
  (0.0, 0.0), (3.0, 0.0), (3.0, 4.0)    // total length: 3 + 4 = 7
])
@lib2d.line_string_interpolate_point(zigzag, 0.5).unwrap()
//   Point(3, 0.5)   (3.5 m in: 3 m on first leg + 0.5 m up on second)
```

Tests in `line_interpolate_point_test.mbt`:

- `line_interpolate_point: f=0 is start`
- `line_interpolate_point: f=1 is end`
- `line_interpolate_point: f=0.5 is midpoint`
- `line_string_interpolate_point: half-way along`

Property test (`property_test.mbt`):

- `property: line_locate ∘ line_interpolate ≈ id`.

## Why a `Point` not a `Coord` for the single-line case

The single-segment `Line` case takes a `Line` (which uses `Coord`s internally) but returns a `Point`. The reason: the result is **conceptually** an interpolated _location_, which the port models as `Point`. For the `LineString` case the result is `Point?` because the input might be empty.

If you want a `Coord` directly, use `result.coord()` to extract.

## Edge cases

- **`t` outside `[0, 1]`**: clamped silently. There is no error / `None` — the caller should rule out out-of-range values up front if that's a bug in their code.
- **Empty / zero-length line string**: `None`.
- **Single-coord line string**: `None` (no segments to interpolate over).

## Performance

`line_interpolate_point`: `O(1)`.

`line_string_interpolate_point`: `O(n)` worst case (walking segments to find which one contains the target). For repeated queries on the same line string, pre-computing a cumulative-length table reduces this to `O(log n)` per query — but the port doesn't currently expose that helper because the typical caller does one or two interpolations per line string, where `O(n)` is fine.

## Related

- `line_locate_point.mbt` — inverse map (coord → `t`).
- `closest_point.mbt` — find the coord, not the parametric position, for an arbitrary target.
- `densify.mbt` — uses `line_interpolate_point` to insert sub-vertices at regular intervals.

# `euclidean.mbt` — straight-line (planar Euclidean) distance, length, bearing, destination

## Goal

Provide the planar (`x`, `y` in metres or whatever unit) versions of the most common line-measurement operations:

- **Distance** between two points / a point and a line / two collections.
- **Length** of a line, line string, or multi-line-string.
- **Bearing** (angle from `+x` axis) between two coords.
- **Destination** — given a start, distance, and bearing, where do you end up?

This is the **planar / Cartesian** family. The geographic / spherical / geodesic variants (`Haversine`, `Geodesic`, `Vincenty`) are explicitly **out of scope** for this port — see `mbt/package/geo-mbt/CLAUDE.md`.

## API surface

| Function                                         | Returns  | What it does                                                                                                         |
| ------------------------------------------------ | -------- | -------------------------------------------------------------------------------------------------------------------- |
| `euclidean_distance_coords(a, b)`                | `Double` | `sqrt((a.x − b.x)² + (a.y − b.y)²)`                                                                                  |
| `euclidean_distance_squared_coords(a, b)`        | `Double` | Skips the `sqrt` — useful when you only need to compare distances                                                    |
| `euclidean_distance_points(a, b)`                | `Double` | Same, but takes `Point`                                                                                              |
| `euclidean_distance_coord_to_line(c, l)`         | `Double` | Shortest distance from `c` to the segment `l` (perpendicular if foot lies on the segment, otherwise nearer endpoint) |
| `euclidean_distance_point_to_line(p, l)`         | `Double` | Same, with `Point` input                                                                                             |
| `euclidean_distance_coord_to_line_string(c, ls)` | `Double` | Min over all segments                                                                                                |
| `euclidean_length_line(l)`                       | `Double` | `magnitude(l.delta())`                                                                                               |
| `euclidean_length_line_string(ls)`               | `Double` | Sum of segment lengths (0 for `< 2` coords)                                                                          |
| `euclidean_length_multi_line_string(mls)`        | `Double` | Sum across all member line strings                                                                                   |
| `euclidean_bearing(from, to)`                    | `Double` | Angle in radians from `+x` axis, `atan2(Δy, Δx)`                                                                     |
| `euclidean_destination(from, distance, bearing)` | `Coord`  | `from + distance · (cos(bearing), sin(bearing))`                                                                     |

## Distance — point to point

```
       b•
       ╱│
      ╱ │ Δy
     ╱  │
    ╱___│
   a    Δx

distance = sqrt(Δx² + Δy²)
```

Just the Pythagorean theorem on the Δ vector.

`euclidean_distance_squared_coords` returns `Δx² + Δy²` without the square root. **Use it whenever you don't need the absolute distance**, e.g. "find the closest of these N points" — comparing squared distances is monotonic with comparing real distances and dodges one `sqrt` per candidate.

## Distance — point to line segment

A bit more involved than point-to-infinite-line. The closest point on a segment depends on whether the **foot of the perpendicular** falls inside the segment:

```
                  • c                     • c                  • c
                   ╲                       │                    ╲
                    ╲                      │                     ╲
   a───●─────b      a─────●─────b      a─────b ●          a────b  ●
       ↑                  ↑                  ↑                    ↑
   foot inside        foot inside       foot past b           foot past b
   distance =         distance =        distance =            distance =
   |c − foot|         |c − foot|        |c − b|               |c − b|
```

The implementation:

1. Parametrise the segment as `a + t · (b − a)` with `t ∈ [0, 1]`.
2. Solve `t* = ((c − a) · (b − a)) / |b − a|²` (the projection scalar).
3. **Clamp** `t = clamp(t*, 0, 1)`. This is what handles the "foot past the endpoint" case.
4. The closest point is `a + t · (b − a)`. Return its distance to `c`.

This is the same algorithm `closest_point.mbt` uses internally; the distance functions just discard the closest-point coordinate at the end.

## Length

For a line: `magnitude(end − start)`.

For a line string: walk consecutive pairs, sum each pair's distance. `O(n)`.

For a multi-line-string: same idea, summed across components.

Empty inputs (0 or 1 coords) return `0`.

## Bearing

```
                ↑ +y
                │
                │     to
                │    ╱
                │   ╱
                │  ╱  bearing
                │ ╱
                │╱_______→ +x
              from
```

`euclidean_bearing(from, to) = atan2(to.y − from.y, to.x − from.x)`.

The result is in **radians, measured CCW from the `+x` axis** — the standard math convention. (Compass bearing measured CW from north would be `π/2 − bearing` after sign flips. The port doesn't add a compass-bearing helper because the planar scope keeps the convention pure.)

## Destination

The inverse of bearing: given a starting `from`, a `distance`, and a `bearing` (radians, CCW from `+x`), return the point you end up at.

```
result = (from.x + distance · cos(bearing),
         from.y + distance · sin(bearing))
```

`euclidean_bearing(from, euclidean_destination(from, d, θ)) ≈ θ` and `euclidean_distance_coords(from, euclidean_destination(from, d, θ)) ≈ d` — these round-trip identities are what `euclidean_test.mbt`'s `euclidean_destination roundtrip with bearing` test exercises.

## Examples

```moonbit nocheck
let a = @type.Coord(0.0, 0.0)
let b = @type.Coord(3.0, 4.0)

@lib2d.euclidean_distance_coords(a, b)   // 5.0  (3-4-5 triangle)
@lib2d.euclidean_distance_squared_coords(a, b)   // 25.0 — no sqrt

let line = @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(10.0, 0.0))
@lib2d.euclidean_distance_coord_to_line(@type.Coord(5.0, 3.0), line)   // 3.0
@lib2d.euclidean_distance_coord_to_line(@type.Coord(15.0, 3.0), line)
//   ↑ foot would land at x=15, beyond endpoint — clamps to (10, 0)
//     distance becomes √(5² + 3²) ≈ 5.83
```

Length of a line string:

```moonbit nocheck
let ls = @type.LineString::from_tuples([(0.0, 0.0), (3.0, 0.0), (3.0, 4.0)])
@lib2d.euclidean_length_line_string(ls)   // 3 + 4 = 7
```

Tests in `euclidean_test.mbt`:

- `euclidean_distance_coords`
- `euclidean_length_line`, `euclidean_length_line_string`
- `euclidean_distance_coord_to_line — point on segment`
- `euclidean_distance_coord_to_line — point off-segment`
- `euclidean_destination roundtrip with bearing`

Plus the bench `bench: euclidean_length_line_string n=100` (`euclidean_bench_test.mbt`).

## Trait API

The free functions above feed into the port-wide `HasLength` trait:

```
HasLength { euclidean_length(self) -> Double }
```

with impls for `Line`, `LineString`, and `MultiLineString`. Use the trait when you want a uniform call site:

```moonbit nocheck
///|
fn[T : @lib2d.HasLength] total(arr : Array[T]) -> Double {
  arr.iter().fold(init=0.0, fn(acc, x) { acc + x.euclidean_length() })
}
```

## Caveats

- **Planar only**. If your coords are longitude/latitude in degrees, this gives nonsense — `(0, 0)` to `(180, 0)` is half the equator (~20 000 km), not `magnitude((180, 0)) = 180`. Project to a metric CRS before using these.
- **No checks for non-finite coordinates.** `NaN` propagates. Use `validation.mbt` upstream if your data may be dirty.
- `euclidean_bearing` returns `0` for identical points (`atan2(0, 0)` is defined as `0` in IEEE-754). If that matters, check for equality first.

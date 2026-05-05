# @totto2727/geo-mbt

MoonBit port of [georust/geo](https://georust.org/).

Scope: 2D planar geometry only, `f64` (`Double`) coordinates only.
3D, geodesic / spherical computations, boolean operations, and triangulation are out of scope for the initial port — see `docs/roadmap/geo-mbt/` for the full roadmap.

## Modules

- `src/geo/2d/type/` — geometry primitives (Coord, Point, Line, LineString, Polygon, etc.)
- `src/geo/2d/` — algorithms (area, bounding rect, distance, contains, etc.)
- `src/robust/` — robust predicates (orient2d, incircle) ported from the [`robust`](https://github.com/georust/robust) crate

# `dimensions.mbt` — OGC dimensionality classification

## Goal

Tell each geometry's **topological dimension** — i.e. how many coordinates you'd need to parametrise its interior:

- **`Empty`** — no points at all
- **`ZeroDimensional`** — points (interior is finite set of locations, dim 0)
- **`OneDimensional`** — line / curve (parametrised by 1 number along its arc, dim 1)
- **`TwoDimensional`** — area (parametrised by 2 numbers in its interior, dim 2)

This classification matches the OGC Simple Features Access spec (the `Dimension` table in §6.1) and the GEOS / JTS `Dimension` enum. It's used internally by `coordinate_position.mbt`, `intersects.mbt`, and the (future) DE-9IM `relate` machinery.

## API surface

```moonbit nocheck
pub(all) enum Dimensions {
  Empty
  ZeroDimensional
  OneDimensional
  TwoDimensional
}

pub fn Dimensions::rank(self) -> Int      // -1 / 0 / 1 / 2  (Empty = -1)
pub fn dimensions_less(a, b) -> Bool      // a.rank() < b.rank()

pub fn dimensions_of_geometry(g)    -> Dimensions
pub fn dimensions_of_line_string(ls) -> Dimensions
pub fn dimensions_of_rect(r)         -> Dimensions
pub fn is_empty_of_geometry(g)       -> Bool        // shortcut for `dim == Empty`
```

## Logic

The dimension depends on **what's actually present**, not just the static type:

| Static type        | Dimension when…                        |
| ------------------ | -------------------------------------- |
| `Point`            | Always `ZeroDimensional`               |
| `MultiPoint`       | `Empty` if no points; else `ZeroDimensional` |
| `Line`             | Always `OneDimensional`                |
| `LineString`       | `Empty` if 0 coords; `ZeroDimensional` if all coords identical (degenerate); else `OneDimensional` |
| `MultiLineString`  | `Empty` if no members or all empty; max of components otherwise |
| `Polygon`          | `Empty` if exterior is empty; `OneDimensional` if `area == 0` (degenerate but shape exists); else `TwoDimensional` |
| `MultiPolygon`     | `Empty` / max of components            |
| `GeometryCollection` | max of all members; `Empty` if all members are empty |
| `Rect`             | `Empty` if `min == max` and degenerate; `OneDimensional` if width or height is 0 (a vertical or horizontal line); else `TwoDimensional` |
| `Triangle`         | Always `TwoDimensional` (the canonical constructor stores three coords; degenerate = collinear = `OneDimensional`) |

The "max of components" rule means a `GeometryCollection` containing both points and a polygon has dimension `TwoDimensional` overall.

## `Dimensions::rank` — for ordering

`rank` maps the enum to an integer so you can compare dimensions:

```
Empty            → -1
ZeroDimensional  →  0
OneDimensional   →  1
TwoDimensional   →  2
```

`dimensions_less(a, b) ⇔ a.rank() < b.rank()`. Useful for picking "the higher-dimensional of two operands" when computing the result dimension of an intersection or boolean op.

## Step-by-step (line string)

```
input: LineString [c₀, c₁, …]

if length == 0:                    return Empty
if all coords equal c₀:            return ZeroDimensional   // degenerate point
                                                            // (e.g. [(1,1),(1,1)])
otherwise:                         return OneDimensional
```

The `ZeroDimensional` case is a quirk of the OGC spec: a line string with all-equal coords represents a single location, so its topological dimension is 0 even though the type is `LineString`.

## Examples

```moonbit nocheck
let pt = @type.Geometry::Point(@type.Point::Point(1.0, 2.0))
@lib2d.dimensions_of_geometry(pt)        // ZeroDimensional

let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
@lib2d.dimensions_of_line_string(ls)     // OneDimensional

let degen = @type.LineString::from_tuples([(0.0, 0.0), (0.0, 0.0)])
@lib2d.dimensions_of_line_string(degen)  // ZeroDimensional

@lib2d.dimensions_of_rect(@type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(0.0, 5.0)))
// width = 0 → OneDimensional (vertical segment)
```

`is_empty_of_geometry` is the friendly shortcut:

```moonbit nocheck
@lib2d.is_empty_of_geometry(@type.Geometry::LineString(@type.LineString::empty()))   // true
```

Tests in `dimensions_test.mbt`:

- `dimensions of basic geometries`
- `degenerate rect dimensions`
- `empty multi point has Empty dimensions`
- `is_empty for various geometries`

## Why this matters

The DE-9IM relate model (used to formalise spatial relations like *touches*, *crosses*, *covers*, *equals*, etc.) compares the dimensions of three sets per pair of geometries: interior-interior, interior-boundary, boundary-boundary. The `Dimensions` enum is the alphabet that machine reads.

This port doesn't implement DE-9IM yet (deferred), but `dimensions.mbt` is the building block — a future `relate` implementation can be layered on top without changing the type surface.

## Related

- `validation.mbt` — checks structural validity (closed rings, ≥ 3 points, etc.) which is **separate from dimensionality**. A polygon with a 2-point ring is structurally invalid; a polygon with all-coincident vertices is valid but `OneDimensional`.

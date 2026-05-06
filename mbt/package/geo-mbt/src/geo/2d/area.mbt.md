# `area.mbt` — signed and unsigned area

## Goal

Compute the **area** of a planar geometry. Two flavours:

- **Signed area** — has a sign that encodes the polygon's winding order. Positive when the vertices are listed counter-clockwise (CCW), negative when clockwise (CW). Empty / degenerate geometries return `0`.
- **Unsigned area** — the absolute value: always `≥ 0`.

The signed form is what most algorithms want internally (it implicitly carries orientation information); the unsigned form is what end users usually want when they ask "how big is this region?".

## API surface

| Function                           | Result           | Notes                                                                    |
| ---------------------------------- | ---------------- | ------------------------------------------------------------------------ |
| `signed_area_of_polygon(p)`        | `Double`         | Exterior contributes positive area, interior rings (holes) subtract      |
| `signed_area_of_multi_polygon(mp)` | `Double`         | Sum of each polygon's signed area                                        |
| `signed_area_of_rect(r)`           | `Double`         | `width * height`. Always non-negative because `Rect` normalises corners  |
| `signed_area_of_triangle(t)`       | `Double`         | Non-robust; uses simple `cross` product                                  |
| `signed_area_of_triangle_robust`   | `Double`         | Same shape, but uses `@robust.orient2d` so the sign is correct near zero |
| `signed_area_of_geometry(g)`       | `Double`         | Dispatch over the `Geometry` enum                                        |
| `unsigned_area_of_*`               | `Double` (`≥ 0`) | `abs(signed_area_of_*)`                                                  |
| `twice_signed_ring_area(ls)`       | `Double`         | Helper: returns `2 × signedArea` for a single closed ring                |

`Point`, `Line`, `LineString`, `MultiLineString`, `MultiPoint` always have area `0` (their dimension is 0 or 1, not 2). The free functions just return `0` for those without dispatching.

## Algorithm — the shoelace formula

For a simple polygon with vertices `(x₀, y₀), (x₁, y₁), …, (xₙ₋₁, yₙ₋₁)`:

```
signed_area = ½ · Σᵢ (xᵢ · yᵢ₊₁  −  xᵢ₊₁ · yᵢ)
            (indices wrap, so xₙ ≡ x₀)
```

The geometric intuition: each segment `(pᵢ → pᵢ₊₁)` contributes a _trapezoid_ between itself and the x-axis, with sign equal to the segment's left-to-right direction. When you sum over a closed ring, the trapezoids that are "outside" the polygon cancel, leaving exactly the polygon's signed area.

The port computes `2 × signed_area` (`twice_signed_ring_area`) and then divides by 2 only at the outermost call. This avoids one floating-point division per ring and is a common implementation trick in geometry libraries.

For a `Polygon` with holes, the exterior ring contributes its signed area, and each interior ring contributes its signed area too. Because conventional winding has interiors going the opposite way to the exterior (CW interior + CCW exterior, or vice versa), the interior signed areas naturally come out with the opposite sign and **subtract** from the exterior. The implementation simply sums them.

## Step-by-step (polygon, single ring)

1. Walk consecutive coordinate pairs `(pᵢ, pᵢ₊₁)`, with `pₙ` wrapping back to `p₀` (the ring is implicitly closed).
2. For each pair, accumulate `xᵢ · yᵢ₊₁ − xᵢ₊₁ · yᵢ`.
3. Divide by 2.

The contribution per edge can also be read as a 2D cross product `(pᵢ × pᵢ₊₁)`, which is why "signed area" and "winding order" are deeply linked — they're computing the same quantity.

## What the sign tells you

Given the convention `+x → right, +y → up`:

- **Positive** signed area ⇒ vertices listed **CCW** (math convention, GeoJSON exterior, OGC SFA exterior).
- **Negative** signed area ⇒ vertices listed **CW** (Shapefile exterior, GeoJSON interior ring).
- **Zero** ⇒ degenerate (collinear, self-overlapping, or empty).

`winding_order(line_string)` is implemented on top of this — it inspects the sign of `twice_signed_ring_area(ls)`.

## Examples

```moonbit nocheck
///|
let unit_square = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]),
  [],
)
// signed_area_of_polygon(unit_square) == 1.0   (CCW exterior)
// unsigned_area_of_polygon(unit_square) == 1.0
```

A polygon with a hole subtracts the hole:

```
exterior:  10×10 square (CCW)        →  +100
interior:   2×2 square (CW)          →   −4
                                     ────
signed_area_of_polygon              =  +96
```

For `Triangle`: the simple version uses one cross product. The `_robust` version routes through `@robust.orient2d`, which is essential when three vertices are _almost_ collinear — without it, the sign can flip due to floating-point rounding.

See `area_test.mbt` for executable cases:

- `signed_area_of_polygon CCW positive`
- `signed_area_of_polygon CW negative`
- `signed_area_of_polygon with hole`
- `signed_area_of_rect is width * height`
- `signed_area_of_triangle`
- `Point/Line/LineString have zero area`

And `kernel_test.mbt` for the robust variant: `signed_area_of_triangle_robust`.

## Property-style checks

`property_test.mbt` includes `property: signed_area flips sign when coords are reversed`, exercising the wind-order ↔ sign correspondence on randomly generated polygons.

## Edge cases

- **Empty geometries** return `0`.
- **Self-intersecting polygons** (the "bowtie" shape) — the formula still produces a value, but it has no useful geometric meaning. The validation layer (`validation.mbt`) is responsible for catching these before they reach `signed_area_of_polygon`.
- **Degenerate triangles** (3 collinear points) → `signed_area = 0` from the simple formula. The robust variant returns `0` too, but importantly it returns _exactly_ `0` rather than a tiny non-zero rounding artefact.

## Performance

`O(n)` where `n` is the total number of coordinates across all rings. A single pass; no allocation. The `bench: signed_area_of_polygon n=100` benchmark in `area_bench_test.mbt` covers this path.

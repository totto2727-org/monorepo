# `traits.mbt` — port-wide trait definitions and impls

## Goal

Define the small handful of traits that allow port-side algorithms to be written **generically over the geometry types** instead of switching on the `Geometry` enum or duplicating implementations per type.

The free functions in the algorithm layer (`coords_of_*`, `bounding_rect_of_*`, `signed_area_of_*`, `centroid_*`, `euclidean_length_*`) are the source of truth — the traits in this file simply route calls to them.

## Traits defined

| Trait              | Method                                | Implementing types                                                                                     |
| ------------------ | ------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `Bounded`          | `bbox(self) -> Rect?`                 | every type variant (`Geometry`, `GeometryCollection`, `Line`, `LineString`, `MultiLineString`, `MultiPoint`, `MultiPolygon`, `Point`, `Polygon`, `Rect`, `Triangle`) |
| `CoordsCarrier`    | `coords(self) -> Array[Coord]`        | every type variant (same set as `Bounded`)                                                            |
| `HasArea`          | `signed_area(self), unsigned_area(self) -> Double` | `Geometry`, `MultiPolygon`, `Polygon`, `Rect`, `Triangle`                                              |
| `HasCentroid`      | `centroid(self) -> Point?`            | `Geometry`, `LineString`, `MultiPolygon`, `Polygon`                                                    |
| `HasLength`        | `euclidean_length(self) -> Double`    | `Line`, `LineString`, `MultiLineString`                                                                |

The trait-method bodies are one-liners that delegate to the matching free function. For example:

```moonbit nocheck
pub impl Bounded for @type.Polygon with bbox(self) {
  bounding_rect_of_polygon(self)
}
pub impl HasArea for @type.Polygon with signed_area(self) {
  signed_area_of_polygon(self)
} and unsigned_area(self) {
  unsigned_area_of_polygon(self)
}
```

## Why traits exist when free functions already cover everything

Two reasons:

1. **Generic algorithms**: a function that takes "anything with a bounding box" can be written as `fn[T : Bounded] f(x : T) -> ...` and called on any of the 11 geometry types without dispatching. This is exactly how a future spatial-index API would consume geometries.
2. **Documentation / discoverability**: the trait list in this file *is* the catalogue of "what every geometry can do". A reader can scan five lines and know the abstraction surface.

## Why some types are missing from `HasArea` etc.

Only types that are **2-dimensional** are in `HasArea` — `Line` / `LineString` would always return `0`, which is technically correct but gives the trait a useless impl. Similarly `HasLength` is restricted to genuinely-1D types.

`Geometry` (the enum) implements all five traits because it dispatches over its variants — for variants that don't carry the relevant dimension, the relevant method returns `0` / `None`.

## Why no `HasPerimeter` etc.

The current scope doesn't need them. If you want a polygon's perimeter, write `euclidean_length_line_string(polygon.exterior())`; for a multi-polygon, sum across components. Adding more traits is cheap when a use case appears, but the port avoids speculative abstractions.

## Examples

```moonbit nocheck
// Generic over anything with a bbox
fn[T : @lib2d.Bounded] union_bbox(arr : Array[T]) -> @type.Rect? {
  arr.iter().fold(init=None, fn(acc, x) {
    match (acc, x.bbox()) {
      (None, b) => b
      (Some(a), None) => Some(a)
      (Some(a), Some(b)) => Some(@type.Rect::Rect(...))   // bbox of bboxes
    }
  })
}

// Generic over anything with length
fn[T : @lib2d.HasLength] total(arr : Array[T]) -> Double {
  arr.iter().fold(init=0.0, fn(acc, x) { acc + x.euclidean_length() })
}
```

Tests in `traits_test.mbt`:

- `CoordsCarrier trait dispatches to per-type impls`
- `Bounded trait works on every variant`
- `HasArea trait on rect`
- `HasCentroid trait on polygon`
- `HasLength trait on line string`
- `generic Bounded constraint usage`

## Performance

Trait dispatch in MoonBit is monomorphised at the call site, so there's no runtime overhead vs. calling the underlying free function directly. The trait abstraction is purely organisational.

## Related

- `coords_iter.mbt`, `bounding_rect.mbt`, `area.mbt`, `centroid.mbt`, `euclidean.mbt` — the free functions every trait method delegates to.
- `coding/mbt-bestpractice.md` §3.7 — port-wide trait conventions.

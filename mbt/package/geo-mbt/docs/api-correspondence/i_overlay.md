# 6. `i_overlay` (+ `iFloat` / `iShape` / `iTree` / `iKeySort`) ↔ `src/geo/2d/bool_ops.mbt`

> **Note**: Phase 2 ms-21 / ms-22 / ms-23 deliver the _same public API_ as
> `i_overlay`'s float-layer (`intersection / union / difference / xor /
unary_union` + line clipping) but implement it via Greiner-Hörmann
> polygon clipping rather than i_overlay's grid-layout sweep. The
> repositories below are cloned for **reference and for a future direct
> port** if i_overlay's higher performance / robustness is needed.

### 6.1 `iOverlay` (the user-facing crate) — public modules

| Rust module / item                                                    | MoonBit port                                                                 | Status | Notes                                                                                                           |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| `core::overlay::Overlay` (DCEL builder)                               | —                                                                            | 🟡     | Port has no DCEL; Greiner-Hörmann walks the original polygon ring directly                                      |
| `core::overlay_rule::OverlayRule`                                     | —                                                                            | 🟡     | Encoded as separate Greiner-Hörmann passes per op                                                               |
| `core::fill_rule::FillRule` (EvenOdd / NonZero / Positive / Negative) | —                                                                            | ⏳     | Port assumes even-odd / non-zero is the same for our simple polygons                                            |
| `core::solver::Solver`                                                | —                                                                            | ⛔     | Not needed — no segment-event queue                                                                             |
| `core::extract::BooleanExtractionBuffer`                              | —                                                                            | ⛔     | Replaced by direct ring walk                                                                                    |
| `segm::{Segment, SegmentFill, ...}`                                   | —                                                                            | ⛔     | Not needed                                                                                                      |
| `split::{Split, SplitSolver, ...}`                                    | —                                                                            | ⛔     | Sutherland-Hodgman / Greiner-Hörmann don't need segment-split machinery                                         |
| `float::*` (float adapter, scaling)                                   | (port runs natively on `Double` so no scaling adapter needed)                | ✅     | Greiner-Hörmann does its own intersection math on `Double` with a `1.0e-12` epsilon                             |
| `float::single::SingleFloatOverlay::overlay`                          | `polygon_intersection`, `polygon_union`, `polygon_difference`, `polygon_xor` | 🟡     | Same surface, different internals                                                                               |
| `float::clip::FloatClip::clip`                                        | `clip_line_string(LineString, Polygon) -> MultiLineString`                   | 🟡     | LineString-clip-by-polygon only; clip-by-polyline (string clipping) not exposed                                 |
| `mesh::stroke::*`, `mesh::offset::*`                                  | `buffer_point` / `buffer_line_string` / `buffer_polygon` (Phase 2 ms-24)     | 🟡     | Mesh layer reproduces stroke/offset surface; uses Greiner-Hörmann union internally rather than i_overlay's mesh |
| `string::*` (line-clip-by-line-set)                                   | —                                                                            | ⏳     | Not yet exposed                                                                                                 |

### 6.2 Dependency crates

| Crate                             | Status | Notes                                                                                                                                                   |
| --------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `i_float` (`IntPoint` / `Fix64`)  | ⛔     | Port stays on raw `f64` (`Double`); no fixed-point integer geometry layer is used                                                                       |
| `i_shape` (paths / shapes)        | ⛔     | Reuses `@type.LineString`, `@type.Polygon`, `@type.MultiPolygon`                                                                                        |
| `i_tree` (RB-tree-ish active set) | ⛔     | `src/geo/2d/sweep.mbt` uses a sorted `Array[SweepInterval]` (acceptable for current input sizes; can be swapped out for an order-statistics tree later) |
| `i_key_sort` (radix-ish sort)     | ⛔     | `Array::sort` from MoonBit core covers the call sites                                                                                                   |

---

# 8. `geographiclib-rs` ↔ (deferred)

> **Note**: Phase 2 ms-32 delivers Haversine (great-circle), Vincenty
> (ellipsoidal inverse), and Rhumb (loxodrome) by porting directly from
> the corresponding files in the `geo` crate
> (`algorithm/line_measures/metric_spaces/{haversine,rhumb}.rs` and
> `algorithm/vincenty_distance.rs`). The Karney geodesic engine in
> `geographiclib-rs` (used by `geo::algorithm::geodesic_*`) is **not yet
> ported** — full geodesic precision is the only major missing distance
> family. The clone below is kept as reference for a future direct port.

### 8.1 Public surface

| Rust upstream item                                                                               | MoonBit port | Status | Notes                                                                                                                                 |
| ------------------------------------------------------------------------------------------------ | ------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| `Geodesic::wgs84()` / `new`                                                                      | —            | ⏳     | The fixed-radius constructor would be straightforward; the algorithmic core (`InverseGeodesic`, series expansions) is the larger lift |
| `Geodesic::inverse`                                                                              | —            | ⏳     |                                                                                                                                       |
| `Geodesic::direct`                                                                               | —            | ⏳     |                                                                                                                                       |
| `Geodesic::area`                                                                                 | —            | ⏳     | (Karney polygon area, distinct from Chamberlain-Duquette spherical area)                                                              |
| Series-expansion helpers (`A1m1`, `A2m1`, `A3coeff`, `C1f`, `C1pf`, `C2f`, `C3coeff`, `C4coeff`) | —            | ⏳     | Internal to Karney's algorithm                                                                                                        |
| `PolygonArea`                                                                                    | —            | ⏳     |                                                                                                                                       |

When ported, the natural port surface would be a `geodesic.mbt` mirroring
the structure of `haversine.mbt` / `rhumb.mbt`.

---

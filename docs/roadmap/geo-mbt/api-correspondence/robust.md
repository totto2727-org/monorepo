# 3. `robust` ↔ `src/robust/`

Port package: `totto2727/geo-mbt/robust` (`src/robust/pkg.generated.mbti`).
The port preserves Shewchuk's helper hierarchy verbatim; it tracks the
upstream Rust `robust` crate (georust) which itself transliterates
Shewchuk's reference implementation.

### 3.1 Public predicates

| Rust upstream item                          | MoonBit port                                     | Status | Notes                    |
| ------------------------------------------- | ------------------------------------------------ | ------ | ------------------------ |
| `pub fn orient2d<T>(pa, pb, pc) -> f64`     | `orient2d(Coord, Coord, Coord) -> Double`        | ✅     | Same return contract     |
| `pub fn incircle<T>(pa, pb, pc, pd) -> f64` | `incircle(Coord, Coord, Coord, Coord) -> Double` | ✅     |                          |
| `pub fn orient3d<T>(pa, pb, pc, pd) -> f64` | —                                                | ⛔     | 3D out of scope          |
| `pub fn insphere<T>(...) -> f64`            | —                                                | ⛔     | 3D out of scope          |
| `pub struct Coord<T>`                       | (uses `@type.Coord`)                             | ✅     | Port reuses geo-2d coord |
| `pub struct Coord3D<T>`                     | —                                                | ⛔     |                          |

### 3.2 Internal helpers (Shewchuk primitives) — `expansion.mbt`

Upstream marks these `fn` (private to the crate); the port re-exports
them as `pub` so that downstream MoonBit code can build other
expansion-based predicates without forking the file.

| Rust private fn                       | MoonBit port                                                                    | Status |
| ------------------------------------- | ------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| `two_sum`                             | `two_sum(Double, Double) -> (Double, Double)`                                   | ✅     |
| `two_sum_tail`                        | `two_sum_tail(Double, Double, Double) -> Double`                                | ✅     |
| `fast_two_sum`                        | `fast_two_sum(Double, Double) -> (Double, Double)`                              | ✅     |
| `fast_two_sum_tail`                   | `fast_two_sum_tail(Double, Double, Double) -> Double`                           | ✅     |
| `two_diff`                            | `two_diff(Double, Double) -> (Double, Double)`                                  | ✅     |
| `two_diff_tail`                       | `two_diff_tail(Double, Double, Double) -> Double`                               | ✅     |
| `split`                               | `split(Double) -> (Double, Double)`                                             | ✅     |
| `two_product`                         | `two_product(Double, Double) -> (Double, Double)`                               | ✅     |
| `two_product_tail` (private)          | (folded into `two_product`)                                                     | 🟡     |
| `two_product_presplit`                | `two_product_presplit(Double, Double, Double, Double) -> (Double, Double)`      | ✅     |
| `square`                              | `square(Double) -> (Double, Double)`                                            | ✅     |
| `square_tail`                         | `square_tail(Double, Double) -> Double`                                         | ✅     |
| (combinator helpers, unnamed in Rust) | `two_one_sum`, `two_one_diff`, `two_two_sum`, `two_two_diff`, `two_one_product` | ✅     |
| `estimate`                            | `estimate(Array[Double], Int) -> Double`                                        | ✅     | Port adds explicit `len` arg (no Rust slice) |
| `fast_expansion_sum_zeroelim`         | `fast_expansion_sum_zeroelim(e, ne, f, nf, h) -> Int`                           | ✅     | Same — explicit lengths                      |
| `scale_expansion_zeroelim`            | `scale_expansion_zeroelim(e, ne, b, h) -> Int`                                  | ✅     |                                              |

### 3.3 Numeric constants

| Rust upstream constant    | MoonBit port     | Value (port)                                   |
| ------------------------- | ---------------- | ---------------------------------------------- |
| `EPSILON`                 | `EPSILON`        | `0.000_000_000_000_000_111_022_302_462_515_65` |
| `SPLITTER`                | `SPLITTER`       | `134_217_729.0`                                |
| `RESULTERRBOUND`          | `RESULTERRBOUND` | `3.33066907388e-16`                            |
| `CCWERRBOUND_A` (private) | (inlined)        | —                                              |
| `CCWERRBOUND_B`           | `CCWERRBOUND_B`  | `2.22044604925e-16`                            |
| `CCWERRBOUND_C`           | `CCWERRBOUND_C`  | `1.10933564797e-31`                            |
| `ICCERRBOUND_A`           | `ICCERRBOUND_A`  | `1.11022302463e-15`                            |
| `ICCERRBOUND_B`           | `ICCERRBOUND_B`  | `4.4408920985e-16`                             |
| `ICCERRBOUND_C`           | `ICCERRBOUND_C`  | `5.42341872339e-31`                            |

### 3.4 Tests / benches

Tests split per source file (post-Step-5 alignment):

- `robust/orient2d_test.mbt` — 4 cases: `collinear`, `counter-clockwise`, `clockwise`, `high-precision tiny inputs`.
- `robust/incircle_test.mbt` — 2 cases: point inside, point outside.

Bench: `robust/orient2d_bench_test.mbt` — `bench: orient2d (robust)`.

Upstream has a `tests.rs` (~30 unit tests) plus `fuzz/` targets. Port
has no fuzzing harness yet (deferred per roadmap post-scope #4).

---

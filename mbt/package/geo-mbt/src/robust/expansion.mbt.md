# `robust/expansion.mbt` — Shewchuk's adaptive-precision floating-point primitives

## Goal

Provide the **building blocks for exact (or controllably-precise) arithmetic on `f64`s**, used by `orient2d.mbt` and `incircle.mbt` when their fast non-adaptive paths can't trust the sign.

The functions in this file are a faithful port of the C reference implementation in Jonathan Shewchuk's 1997 paper _Adaptive Precision Floating-Point Arithmetic and Fast Robust Geometric Predicates_. They let you represent a value as an **expansion** — a sum of `f64`s with non-overlapping bit ranges — and perform arithmetic on expansions exactly.

You probably don't need to call these directly; they're tooling for `orient2d` and `incircle`. The port keeps them `pub` so future predicates (e.g. `orient3d`, `insphere`, custom domain-specific robust tests) can be built without forking the file.

## API surface

The primitives are organised by what they compute. Each comes in two flavours:

- `_sum` / `_diff` / `_product` returns a 2-tuple `(high, low)` — the sum's IEEE-754-rounded result plus the round-off error.
- `_tail` returns just the round-off (the second component), when only that is needed.
- Multi-argument forms (`two_one_sum`, `two_two_sum`, etc.) extend to expansions of size 2 or 3.

Listing:

| Function                                       | Purpose                                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------------ | --- | --- | --- | --- |
| `two_sum(a, b)`                                | Return `(s, e)` such that `s = round(a + b)` and `e = (a + b) − s` exactly           |
| `two_sum_tail(a, b, x)`                        | Just the round-off `(a + b) − x` given precomputed `x`                               |
| `fast_two_sum(a, b)`                           | Like `two_sum`, faster when `                                                        | a   | ≥   | b   | `   |
| `fast_two_sum_tail(a, b, x)`                   | Just the round-off                                                                   |
| `two_diff(a, b)`                               | `(s, e)` such that `s = round(a − b)`, `e = (a − b) − s`                             |
| `two_diff_tail(a, b, x)`                       | Round-off                                                                            |
| `split(a)`                                     | Split `a` into high and low halves of equal bit-width (used for two_product)         |
| `two_product(a, b)`                            | `(p, e)` such that `p = round(a · b)`, `e = (a · b) − p`                             |
| `two_product_presplit(a, b, hi, lo)`           | Same, but with `b` already split — saves one `split` call when reusing `b`           |
| `square(a)`                                    | Specialised `(p, e) = (a², round-off)`                                               |
| `square_tail(a, x)`                            | Round-off only                                                                       |
| `two_one_sum(a1, a0, b)`                       | Sum a 2-component expansion `[a1, a0]` with a single `f64` `b`, returns 3 components |
| `two_one_diff(...)`, `two_one_product(...)`    | Same shape, for diff and product                                                     |
| `two_two_sum(a1, a0, b1, b0)`                  | Sum two 2-component expansions, returns 4 components                                 |
| `two_two_diff(...)`                            | Diff of two 2-component expansions                                                   |
| `estimate(e, n)`                               | Single-`f64` estimate of an expansion's value (for early-out checks)                 |
| `fast_expansion_sum_zeroelim(e, ne, f, nf, h)` | Sum two expansions, write to `h`, return result length                               |
| `scale_expansion_zeroelim(e, ne, b, h)`        | Multiply an expansion by an `f64`, write to `h`                                      |

Plus the constants `EPSILON`, `SPLITTER`, `RESULTERRBOUND`, `CCWERRBOUND_*`, `ICCERRBOUND_*` — error bounds derived from machine epsilon, used to decide when Stage 1 is reliable.

## What an "expansion" is

A standard `f64` has 53 bits of mantissa. Two `f64`s together can represent ~106 useful bits. Three give ~159 bits. An **expansion** is just an array of `f64`s where consecutive components are sorted by magnitude descending and **don't overlap in bit range**:

```
expansion [3.14e10, 4.21e-7]
                    ↑
       The "tail" is much smaller than the "head" and lives in
       the lower bits of the represented value.
```

The mathematical value the expansion stands for is the **sum** of its components. By keeping components non-overlapping, you can do exact arithmetic on them: each operation produces a new expansion whose true value is exactly the result of the operation.

## The two foundational operations

Two operations form the basis of every other primitive:

### `two_sum(a, b)` — error-free transformation of addition

Returns `(x, y)` with `x = round(a + b)` and `x + y = a + b` _exactly_. The `y` is the round-off error captured as a separate `f64`.

```
a = 1e16
b = 1
naive a + b = 1e16  (b is rounded away)

two_sum(a, b):
  x = 1e16 + 1 = 1e16   (same naive result)
  y = (a + b) − x = 1   (exact: the lost bit, captured)

x + y = 1e16 + 1   exactly equals a + b
```

This is **error-free addition**: no precision is lost, but the result may need 2 `f64`s instead of 1.

### `two_product(a, b)` — error-free transformation of multiplication

Same idea: `(p, e)` with `p = round(a · b)`, `p + e = a · b` exactly. Implemented via the **split-and-multiply trick** (`split` first divides each operand into high and low halves so the partial products fit exactly in `f64`).

## Higher-level operations

`fast_expansion_sum_zeroelim` adds two expansions. If `e = [e_n, e_{n-1}, ..., e_0]` and `f = [f_m, ..., f_0]`, the sum is computed by merging components by magnitude and applying `two_sum` to neighbours, building a new expansion. The "zeroelim" suffix means trailing zeros are stripped (an expansion of length 0 represents 0 exactly).

`scale_expansion_zeroelim` multiplies an expansion by a single `f64`. Same idea: distribute, then re-add the partial products with `two_sum`.

`estimate` collapses an expansion to a single `f64` for quick comparisons (e.g. "is this clearly positive?").

## Error bounds

The constants like `CCWERRBOUND_A` are derived in the Shewchuk paper. They answer: "given inputs of magnitude up to `M`, what is the worst-case error in the naive `f64` orient determinant?" If the naive result exceeds the bound, the sign is trustworthy. Otherwise refine to expansion arithmetic.

## When to read this file vs. `orient2d.mbt`

- **`orient2d.mbt` / `incircle.mbt`**: how robust geometric predicates are _used_. This is what algorithm code calls.
- **`expansion.mbt`**: how robust arithmetic _works underneath_. Read this when extending the port with new robust predicates, or debugging a precision issue.

## Testing

The expansion primitives don't have dedicated unit tests in the port — they're tested transitively through `orient2d` and `incircle` tests:

- `robust/orient2d_test.mbt` — `orient2d high-precision tiny inputs` exercises Stage 2 refinement, which exercises `expansion`-level operations.

## Performance

Each primitive is a few `f64` operations. Per-operation latency is in the low nanoseconds; the cost of robust predicates comes mostly from the _number_ of operations needed in Stage 2, not from any single primitive's slowness.

## Related

- `orient2d.mbt`, `incircle.mbt` — the consumers.
- The original Shewchuk paper: <https://www.cs.cmu.edu/~quake/robust.html>.
- `coord.mbt`'s simple cross product — the **non-robust** version used by `signed_area_of_triangle` (vs. `signed_area_of_triangle_robust` which goes through this file).

# 9. `num-traits` (not used)

> **Note**: `num-traits` provides the `Float` / `FromPrimitive` / `CoordFloat`
> abstractions that the Rust `geo` ecosystem uses to be generic over `f32`
> vs `f64` vs fixed-point types. The MoonBit port **hard-codes** `Double`
> (`f64`) per its scope rules, so no numeric-trait machinery is needed.
> The clone is kept only because `geographiclib-rs` and `geo` import it
> via `Cargo.toml` and the offline-reference convention is to vendor every
> transitive dependency.

No port-side equivalent is planned.

---

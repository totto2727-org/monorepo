# Point in Polygon

Based on JS implementation: <https://github.com/rowanwins/point-in-polygon-hao/blob/938b2be31d326c52c8f6cffbbb1c59bae4d609bc/src/index.js>

## Status

Implemented the following function:

- [x] `point_in_polygon`: Determine if a point is inside a polygon (Ray Casting algorithm with robust predicates)

## Differences from Original Implementation

The [Robust implementation for JS](https://github.com/mourner/robust-predicates) referenced by the original library contains the following note:

```md
Note: unlike J. Shewchuk's original code, all the functions in this library assume y axis is oriented downwards ↓, so the semantics are different.
```

Since the Robust implementation in this library adopts a standard coordinate system, the signs of some calculations are reversed compared to the original implementation.

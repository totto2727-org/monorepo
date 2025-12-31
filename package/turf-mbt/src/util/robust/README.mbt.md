# Robust Geometric Predicates

MoonBit port of Jonathan Richard Shewchuk's robust floating-point arithmetic algorithms.

Reference: <https://www.cs.cmu.edu/~quake/robust.html>

Original Rust implementation: <https://github.com/georust/robust/blob/654f34cb8cdb3ae21bf59ef3472f92652942cd74/src/lib.rs>

## Status

Implemented the following functions:

- [x] `orient2d`
- [x] `orient3d`
- [x] `incircle`
- [x] `insphere`

## Overview

Adaptive precision algorithms to resolve inaccuracies in geometric predicates caused by floating-point rounding errors.

## Main Functions

### orient2d(point_a_x, point_a_y, point_b_x, point_b_y, point_c_x, point_c_y) -> Double

Determines the orientation of three points (pa, pb, pc).

- **Positive**: `pc` lies to the **left** of the line `pa->pb` (Counter-Clockwise)
- **Negative**: `pc` lies to the **right** of the line `pa->pb` (Clockwise)
- **Zero**: The three points are collinear

Reference: <https://gemini.google.com/share/2af46502682f>

### orient3d(...) -> Double

Determines the orientation of four points (pa, pb, pc, pd).

- **Positive**: `pd` lies **above** the plane `pa-pb-pc` (Outside)
- **Negative**: `pd` lies **below** the plane `pa-pb-pc` (Inside)
- **Zero**: The four points are coplanar

### incircle(...) -> Double

Determines if point `pd` lies inside the circumcircle of the triangle defined by three points (pa, pb, pc) arranged in counter-clockwise order.

- **Positive**: `pd` lies **inside** the circle
- **Negative**: `pd` lies **outside** the circle
- **Zero**: `pd` lies **on** the circle boundary

### insphere(...) -> Double

Determines if point `pe` lies inside the circumsphere of the tetrahedron defined by four points (pa, pb, pc, pd) arranged in counter-clockwise order.

- **Positive**: `pe` lies **inside** the sphere
- **Negative**: `pe` lies **outside** the sphere
- **Zero**: `pe` lies **on** the sphere surface

## Algorithm Stages

1. **Fast Path**: Checks if the result can be determined using simple determinant calculations.
2. **Adaptive Precision**: Performs high-precision calculations only when necessary.

## Low-level Operations

### Two-Sum / Two-Diff

Basic operations to achieve error-free addition and subtraction.

```moonbit
two_sum(a, b) -> (x, y) // a + b = x + y (exact)
two_diff(a, b) -> (x, y) // a - b = x + y (exact)
```

### Two-Product

Achieves error-free multiplication. Uses the `split` function to divide the mantissa and correct the error of partial products.

```moonbit
two_product(a, b) -> (x, y) // a * b = x + y (exact)
```

### Expansion Arithmetic

Arithmetic operations between variable-precision numbers (expansions).

- `fast_expansion_sum_zeroelim`: Sum of two Expansions
- `scale_expansion_zeroelim`: Product of an Expansion and a scalar

///|
priv struct Coord {
  x : Double
  y : Double
}

///|
priv struct Coord3D {
  x : Double
  y : Double
  z : Double
}

///|
fn to_coord(p : @geojson.Position) -> Coord {
  match p {
    Position2D(x, y) => { x, y }
    Position3D(x, y, _) => { x, y }
  }
}

///|
fn to_coord3d(p : @geojson.Position) -> Coord3D raise {
  match p {
    Position3D(x, y, z) => { x, y, z }
    Position2D(_) => fail("orient3d/insphere requires 3D position")
  }
}

///|
/// Returns the absolute value
fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
/// Splits a double precision value into two parts (Veltkamp's algorithm)
///
/// Splits double precision floating point number `a` into `a_hi` and `a_lo` such that `a = a_hi + a_lo`.
/// Ensures that more than half of the mantissa of both values is zero, enabling error-free multiplication.
fn split(a : Double) -> (Double, Double) {
  let c = splitter * a
  let abig = c - a
  let ahi = c - abig
  let alo = a - ahi
  (ahi, alo)
}

///|
/// Calculates the error term of the product of two values
///
/// When `x` is the rounded result of `a * b`, returns `err` such that `a * b = x + err`.
fn two_product_tail(a : Double, b : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let (bhi, blo) = split(b)
  // Calculate partial products
  let err1 = x - ahi * bhi
  let err2 = err1 - alo * bhi
  let err3 = err2 - ahi * blo
  alo * blo - err3
}

///|
/// Calculates exact product (Dekker's algorithm)
///
/// Returns `(x, y)` such that `a * b = x + y`. `x` is the rounded product, `y` is the error term.
fn two_product(a : Double, b : Double) -> (Double, Double) {
  let x = a * b
  (x, two_product_tail(a, b, x))
}

///|
fn two_product_presplit(
  a : Double,
  b : Double,
  bhi : Double,
  blo : Double,
) -> (Double, Double) {
  let x = a * b
  let (ahi, alo) = split(a)
  let err1 = x - ahi * bhi
  let err2 = err1 - alo * bhi
  let err3 = err2 - ahi * blo
  let y = alo * blo - err3
  (x, y)
}

///|
/// Calculates the error term of the sum of two values (Knuth's TwoSum)
///
/// When `x` is the rounded result of `a + b`, returns `err` such that `a + b = x + err`.
fn two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  let avirt = x - bvirt
  let bround = b - bvirt
  let around = a - avirt
  around + bround
}

///|
/// Calculates exact sum (Knuth's TwoSum)
///
/// Returns `(x, y)` such that `a + b = x + y`. `x` is the rounded sum, `y` is the error term.
fn two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, two_sum_tail(a, b, x))
}

///|
/// Fast TwoSum error term calculation valid when |a| >= |b|
fn fast_two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  b - bvirt
}

///|
/// Fast TwoSum valid when |a| >= |b|
fn fast_two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, fast_two_sum_tail(a, b, x))
}

///|
/// Calculates exact difference
fn two_diff_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = a - x
  let avirt = x + bvirt
  let bround = bvirt - b
  let around = a - avirt
  around + bround
}

///|
/// Calculates exact difference
fn two_diff(a : Double, b : Double) -> (Double, Double) {
  let x = a - b
  (x, two_diff_tail(a, b, x))
}

///|
/// Calculates the error term of the square
fn square_tail(a : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let err1 = x - ahi * ahi
  let err3 = err1 - (ahi + ahi) * alo
  alo * alo - err3
}

///|
/// Calculates exact square
fn square(a : Double) -> (Double, Double) {
  let x = a * a
  (x, square_tail(a, x))
}

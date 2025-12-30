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
/// 絶対値を返す
fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
/// 倍精度の値を2つの部分に分割する（Veltkampのアルゴリズム）
///
/// 倍精度浮動小数点数 `a` を `a_hi` と `a_lo` に分割し、`a = a_hi + a_lo` となるようにする。
/// 両方の値の仮数部の半分以上がゼロであることを保証し、誤差なしの乗算を可能にする。
fn split(a : Double) -> (Double, Double) {
  let c = splitter * a
  let abig = c - a
  let ahi = c - abig
  let alo = a - ahi
  (ahi, alo)
}

///|
/// 2つの値の積の誤差項を計算する
///
/// `x` が `a * b` の丸められた結果であるとき、`a * b = x + err` となる `err` を返す。
fn two_product_tail(a : Double, b : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let (bhi, blo) = split(b)
  // 部分積の計算
  let err1 = x - ahi * bhi
  let err2 = err1 - alo * bhi
  let err3 = err2 - ahi * blo
  alo * blo - err3
}

///|
/// 誤差なしの積を計算する（Dekkerのアルゴリズム）
///
/// `a * b = x + y` となる `(x, y)` を返す。`x` は丸められた積、`y` は誤差項。
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
/// 2つの値の和の誤差項を計算する（KnuthのTwoSum）
///
/// `x` が `a + b` の丸められた結果であるとき、`a + b = x + err` となる `err` を返す。
fn two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  let avirt = x - bvirt
  let bround = b - bvirt
  let around = a - avirt
  around + bround
}

///|
/// 誤差なしの和を計算する（KnuthのTwoSum）
///
/// `a + b = x + y` となる `(x, y)` を返す。`x` は丸められた和、`y` は誤差項。
fn two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, two_sum_tail(a, b, x))
}

///|
/// |a| >= |b| の場合に有効な高速なTwoSum誤差項計算
fn fast_two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  b - bvirt
}

///|
/// |a| >= |b| の場合に有効な高速なTwoSum
fn fast_two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, fast_two_sum_tail(a, b, x))
}

///|
/// 誤差なしの差を計算する
fn two_diff_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = a - x
  let avirt = x + bvirt
  let bround = bvirt - b
  let around = a - avirt
  around + bround
}

///|
/// 誤差なしの差を計算する
fn two_diff(a : Double, b : Double) -> (Double, Double) {
  let x = a - b
  (x, two_diff_tail(a, b, x))
}

///|
/// 自乗の誤差項を計算する
fn square_tail(a : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let err1 = x - ahi * ahi
  let err3 = err1 - (ahi + ahi) * alo
  alo * alo - err3
}

///|
/// 誤差なしの自乗を計算する
fn square(a : Double) -> (Double, Double) {
  let x = a * a
  (x, square_tail(a, x))
}

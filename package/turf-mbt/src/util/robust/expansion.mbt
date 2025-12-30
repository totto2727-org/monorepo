///|
/// Expansion（多倍精度浮動小数点数）の値を推定する（近似値を返す）
fn estimate(e : FixedArray[Double], len : Int) -> Double {
  let mut q = e[0]
  for i = 1; i < len; i = i + 1 {
    q = q + e[i]
  }
  q
}

///|
/// 2つのExpansionの和を計算する。ゼロ要素は除去される。
fn fast_expansion_sum_zeroelim(
  e : FixedArray[Double],
  e_length : Int,
  f : FixedArray[Double],
  f_length : Int,
  h : FixedArray[Double],
) -> Int {
  let mut e_now = e[0]
  let mut f_now = f[0]
  let mut e_index = 0
  let mut f_index = 0
  let mut q = 0.0
  if (f_now > e_now) == (f_now > -e_now) {
    q = e_now
    e_index = e_index + 1
  } else {
    q = f_now
    f_index = f_index + 1
  }
  let mut h_index = 0
  if e_index < e_length && f_index < f_length {
    e_now = e[e_index]
    f_now = f[f_index]
    let mut q_new = 0.0
    let mut hh = 0.0
    if (f_now > e_now) == (f_now > -e_now) {
      let r = fast_two_sum(e_now, q)
      q_new = r.0
      hh = r.1
      e_index = e_index + 1
    } else {
      let r = fast_two_sum(f_now, q)
      q_new = r.0
      hh = r.1
      f_index = f_index + 1
    }
    q = q_new
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
    while e_index < e_length && f_index < f_length {
      e_now = e[e_index]
      f_now = f[f_index]
      if (f_now > e_now) == (f_now > -e_now) {
        let r = two_sum(q, e_now)
        q_new = r.0
        hh = r.1
        e_index = e_index + 1
      } else {
        let r = two_sum(q, f_now)
        q_new = r.0
        hh = r.1
        f_index = f_index + 1
      }
      q = q_new
      if hh != 0.0 {
        h[h_index] = hh
        h_index = h_index + 1
      }
    }
  }
  while e_index < e_length {
    e_now = e[e_index]
    let r = two_sum(q, e_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    e_index = e_index + 1
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
  }
  while f_index < f_length {
    f_now = f[f_index]
    let r = two_sum(q, f_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    f_index = f_index + 1
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
  }
  if q != 0.0 || h_index == 0 {
    h[h_index] = q
    h_index = h_index + 1
  }
  h_index
}

///|
/// Expansionとスカラの積を計算する。ゼロ要素は除去される。
fn scale_expansion_zeroelim(
  e : FixedArray[Double],
  e_length : Int,
  b : Double,
  h : FixedArray[Double],
) -> Int {
  let (b_hi, b_lo) = split(b)
  let r = two_product_presplit(e[0], b, b_hi, b_lo)
  let mut q = r.0
  let hh = r.1
  let mut h_index = 0
  if hh != 0.0 {
    h[h_index] = hh
    h_index = h_index + 1
  }
  for e_index = 1; e_index < e_length; e_index = e_index + 1 {
    let e_now = e[e_index]
    let (product1, product0) = two_product_presplit(e_now, b, b_hi, b_lo)
    let (sum, hh_2) = two_sum(q, product0)
    if hh_2 != 0.0 {
      h[h_index] = hh_2
      h_index = h_index + 1
    }
    let (new_q, hh_3) = fast_two_sum(product1, sum)
    q = new_q
    if hh_3 != 0.0 {
      h[h_index] = hh_3
      h_index = h_index + 1
    }
  }
  if q != 0.0 || h_index == 0 {
    h[h_index] = q
    h_index = h_index + 1
  }
  h_index
}

///|
fn two_one_product(
  a_1 : Double,
  a_0 : Double,
  b : Double,
) -> (Double, Double, Double, Double) {
  let (b_hi, b_lo) = split(b)
  let (i, x_0) = two_product_presplit(a_0, b, b_hi, b_lo)
  let (j, p_0) = two_product_presplit(a_1, b, b_hi, b_lo)
  let (k, x_1) = two_sum(i, p_0)
  let (x_3, x_2) = fast_two_sum(j, k)
  (x_3, x_2, x_1, x_0)
}

///|
/// Expansion (a1, a0) とスカラ b の差を計算する (x2, x1, x0)
fn two_one_diff(
  a_1 : Double,
  a_0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (i, x_0) = two_diff(a_0, b)
  let (x_2, x_1) = two_sum(a_1, i)
  (x_2, x_1, x_0)
}

///|
/// Expansion (a1, a0) と Expansion (b1, b0) の差を計算する (x3, x2, x1, x0)
fn two_two_diff(
  a_1 : Double,
  a_0 : Double,
  b_1 : Double,
  b_0 : Double,
) -> (Double, Double, Double, Double) {
  let (j, _r0, x_0) = two_one_diff(a_1, a_0, b_0)
  let (x_3, x_2, x_1) = two_one_diff(j, _r0, b_1)
  (x_3, x_2, x_1, x_0)
}

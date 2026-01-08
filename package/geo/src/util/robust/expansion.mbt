///|
priv struct Expansion {
  data : FixedArray[Double]
  length : Int
}

///|
fn Expansion::from_fixed_array(array : FixedArray[Double]) -> Expansion {
  { data: array, length: array.length() }
}

///|
/// Expansion（多倍精度浮動小数点数）の値を推定する（近似値を返す）
fn Expansion::estimate(self : Expansion) -> Double {
  let mut sum = 0.0
  for i = 0; i < self.length; i = i + 1 {
    sum += self.data[i]
  }
  sum
}

///|
/// Truncates the internal buffer of the Expansion to its current logical length.
fn Expansion::truncate(self : Expansion, length : Int) -> Expansion {
  { data: self.data, length }
}

///|
/// Sum of two Expansions
///
/// Corresponds to `Fast-Expansion-Sum` in Shewchuk's paper (variant with zero elimination).
fn Expansion::fast_expansion_sum_zeroelim(
  self : Expansion,
  other : Expansion,
) -> Expansion {
  // TODO: Consider handling empty arrays (length == 0)
  let new_data = Expansion::from_fixed_array(
    FixedArray::make(self.data.length() + other.data.length(), 0.0),
  )
  let mut self_now = self.data[0]
  let mut other_now = other.data[0]
  let mut self_index = 0
  let mut other_index = 0
  let mut new_index = 0
  let mut q = 0.0
  if (other_now > self_now) == (other_now > -self_now) {
    q = self_now
    self_index = self_index + 1
  } else {
    q = other_now
    other_index = other_index + 1
  }
  if self_index < self.data.length() && other_index < other.data.length() {
    self_now = self.data[self_index]
    other_now = other.data[other_index]
    let mut q_new = 0.0
    let mut hh = 0.0
    if (other_now > self_now) == (other_now > -self_now) {
      let r = fast_two_sum(self_now, q)
      q_new = r.0
      hh = r.1
      self_index = self_index + 1
    } else {
      let r = fast_two_sum(other_now, q)
      q_new = r.0
      hh = r.1
      other_index = other_index + 1
    }
    q = q_new
    if hh != 0.0 {
      new_data.data[new_index] = hh
      new_index = new_index + 1
    }
    while self_index < self.data.length() && other_index < other.data.length() {
      self_now = self.data[self_index]
      other_now = other.data[other_index]
      if (other_now > self_now) == (other_now > -self_now) {
        let r = two_sum(q, self_now)
        q_new = r.0
        hh = r.1
        self_index = self_index + 1
      } else {
        let r = two_sum(q, other_now)
        q_new = r.0
        hh = r.1
        other_index = other_index + 1
      }
      q = q_new
      if hh != 0.0 {
        new_data.data[new_index] = hh
        new_index = new_index + 1
      }
    }
  }
  while self_index < self.data.length() {
    self_now = self.data[self_index]
    let r = two_sum(q, self_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    self_index = self_index + 1
    if hh != 0.0 {
      new_data.data[new_index] = hh
      new_index = new_index + 1
    }
  }
  while other_index < other.data.length() {
    other_now = other.data[other_index]
    let r = two_sum(q, other_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    other_index = other_index + 1
    if hh != 0.0 {
      new_data.data[new_index] = hh
      new_index = new_index + 1
    }
  }
  if q != 0.0 || new_index == 0 {
    new_data.data[new_index] = q
    new_index = new_index + 1
  }
  new_data.truncate(new_index)
}

///|
/// Computes the product of an Expansion and a scalar. Zero elements are eliminated.
fn Expansion::scale_expansion_zeroelim(
  self : Expansion,
  b : Double,
) -> Expansion {
  // TODO: Consider handling empty arrays (length == 0)
  let new_data = Expansion::from_fixed_array(
    FixedArray::make(self.data.length() * 2, 0.0),
  )
  let (b_hi, b_lo) = split(b)
  let r = two_product_presplit(self.data[0], b, b_hi, b_lo)
  let mut q = r.0
  let hh = r.1
  let mut new_index = 0
  if hh != 0.0 {
    new_data.data[new_index] = hh
    new_index = new_index + 1
  }
  for e_index = 1; e_index < self.data.length(); e_index = e_index + 1 {
    let e_now = self.data[e_index]
    let (product1, product0) = two_product_presplit(e_now, b, b_hi, b_lo)
    let (sum, hh_2) = two_sum(q, product0)
    if hh_2 != 0.0 {
      new_data.data[new_index] = hh_2
      new_index = new_index + 1
    }
    let (new_q, hh_3) = fast_two_sum(product1, sum)
    q = new_q
    if hh_3 != 0.0 {
      new_data.data[new_index] = hh_3
      new_index = new_index + 1
    }
  }
  if q != 0.0 || new_index == 0 {
    new_data.data[new_index] = q
    new_index = new_index + 1
  }
  new_data.truncate(new_index)
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

// Ported from georust/robust expansion / floating-point primitives.
// Reference also: mbt/package/geo/src/util/robust/orient2d.mbt — these are
// the helper functions Shewchuk's predicates rely on, factored out so they
// can be reused by both `orient2d` and `incircle`.

///|
pub const SPLITTER : Double = 134_217_729.0

///|
pub const EPSILON : Double = 0.000_000_000_000_000_111_022_302_462_515_65

///|
pub const RESULTERRBOUND : Double = (3.0 + 8.0 * EPSILON) * EPSILON

///|
pub const CCWERRBOUND_B : Double = (2.0 + 12.0 * EPSILON) * EPSILON

///|
pub const CCWERRBOUND_C : Double = (9.0 + 64.0 * EPSILON) * EPSILON * EPSILON

///|
pub const ICCERRBOUND_A : Double = (10.0 + 96.0 * EPSILON) * EPSILON

///|
pub const ICCERRBOUND_B : Double = (4.0 + 48.0 * EPSILON) * EPSILON

///|
pub const ICCERRBOUND_C : Double = (44.0 + 576.0 * EPSILON) * EPSILON * EPSILON

///|
pub fn estimate(e : Array[Double], len : Int) -> Double {
  let mut q = e[0]
  for i = 1; i < len; i = i + 1 {
    q += e[i]
  }
  q
}

///|
pub fn two_product(a : Double, b : Double) -> (Double, Double) {
  let x = a * b
  (x, two_product_tail(a, b, x))
}

///|
fn two_product_tail(a : Double, b : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let (bhi, blo) = split(b)
  let err1 = x - ahi * bhi
  let err2 = err1 - alo * bhi
  let err3 = err2 - ahi * blo
  alo * blo - err3
}

///|
pub fn split(a : Double) -> (Double, Double) {
  let c = SPLITTER * a
  let abig = c - a
  let ahi = c - abig
  let alo = a - ahi
  (ahi, alo)
}

///|
pub fn two_product_presplit(
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
pub fn two_two_diff(
  a1 : Double,
  a0 : Double,
  b1 : Double,
  b0 : Double,
) -> (Double, Double, Double, Double) {
  let (j, _r0, x0) = two_one_diff(a1, a0, b0)
  let (x3, x2, x1) = two_one_diff(j, _r0, b1)
  (x3, x2, x1, x0)
}

///|
pub fn two_one_diff(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (i, x0) = two_diff(a0, b)
  let (x2, x1) = two_sum(a1, i)
  (x2, x1, x0)
}

///|
pub fn two_diff(a : Double, b : Double) -> (Double, Double) {
  let x = a - b
  (x, two_diff_tail(a, b, x))
}

///|
pub fn two_diff_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = a - x
  let avirt = x + bvirt
  let bround = bvirt - b
  let around = a - avirt
  around + bround
}

///|
pub fn two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, two_sum_tail(a, b, x))
}

///|
pub fn two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  let avirt = x - bvirt
  let bround = b - bvirt
  let around = a - avirt
  around + bround
}

///|
pub fn fast_two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, fast_two_sum_tail(a, b, x))
}

///|
pub fn fast_two_sum_tail(a : Double, _b : Double, x : Double) -> Double {
  let bvirt = x - a
  _b - bvirt
}

///|
pub fn square(a : Double) -> (Double, Double) {
  let x = a * a
  (x, square_tail(a, x))
}

///|
pub fn square_tail(a : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let err1 = x - ahi * ahi
  let err3 = err1 - (ahi + ahi) * alo
  alo * alo - err3
}

///|
pub fn two_one_sum(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (_i, x0) = two_sum(a0, b)
  let (x2, x1) = two_sum(a1, _i)
  (x2, x1, x0)
}

///|
pub fn two_two_sum(
  a1 : Double,
  a0 : Double,
  b1 : Double,
  b0 : Double,
) -> (Double, Double, Double, Double) {
  let (_j, _r0, x0) = two_one_sum(a1, a0, b0)
  let (x3, x2, x1) = two_one_sum(_j, _r0, b1)
  (x3, x2, x1, x0)
}

///|
pub fn two_one_product(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double, Double) {
  let (bhi, blo) = split(b)
  let (i_val, x0) = two_product_presplit(a0, b, bhi, blo)
  let (j_val, val0) = two_product_presplit(a1, b, bhi, blo)
  let (k_val, x1) = two_sum(i_val, val0)
  let (x3, x2) = fast_two_sum(j_val, k_val)
  (x3, x2, x1, x0)
}

///|
pub fn fast_expansion_sum_zeroelim(
  e : Array[Double],
  elen : Int,
  f : Array[Double],
  flen : Int,
  h : Array[Double],
) -> Int {
  let mut enow = e[0]
  let mut fnow = f[0]
  let mut eindex = 0
  let mut findex = 0
  let mut qnew = 0.0
  let mut hh = 0.0
  let mut q = 0.0
  if (fnow > enow) == (fnow > -enow) {
    q = enow
    eindex += 1
  } else {
    q = fnow
    findex += 1
  }
  let mut hindex = 0
  if eindex < elen && findex < flen {
    enow = e[eindex]
    fnow = f[findex]
    if (fnow > enow) == (fnow > -enow) {
      let r = fast_two_sum(enow, q)
      qnew = r.0
      hh = r.1
      eindex += 1
    } else {
      let r = fast_two_sum(fnow, q)
      qnew = r.0
      hh = r.1
      findex += 1
    }
    q = qnew
    if hh != 0.0 {
      h[hindex] = hh
      hindex += 1
    }
    while eindex < elen && findex < flen {
      enow = e[eindex]
      fnow = f[findex]
      if (fnow > enow) == (fnow > -enow) {
        let r = two_sum(q, enow)
        qnew = r.0
        hh = r.1
        eindex += 1
      } else {
        let r = two_sum(q, fnow)
        qnew = r.0
        hh = r.1
        findex += 1
      }
      q = qnew
      if hh != 0.0 {
        h[hindex] = hh
        hindex += 1
      }
    }
  }
  while eindex < elen {
    enow = e[eindex]
    let r = two_sum(q, enow)
    qnew = r.0
    hh = r.1
    q = qnew
    eindex += 1
    if hh != 0.0 {
      h[hindex] = hh
      hindex += 1
    }
  }
  while findex < flen {
    fnow = f[findex]
    let r = two_sum(q, fnow)
    qnew = r.0
    hh = r.1
    q = qnew
    findex += 1
    if hh != 0.0 {
      h[hindex] = hh
      hindex += 1
    }
  }
  if q != 0.0 || hindex == 0 {
    h[hindex] = q
    hindex += 1
  }
  hindex
}

///|
pub fn scale_expansion_zeroelim(
  e : Array[Double],
  elen : Int,
  b : Double,
  h : Array[Double],
) -> Int {
  let (bhi, blo) = split(b)
  let q_hh = two_product_presplit(e[0], b, bhi, blo)
  let mut q = q_hh.0
  let hh = q_hh.1
  let mut hindex = 0
  if hh != 0.0 {
    h[hindex] = hh
    hindex += 1
  }
  for eindex = 1; eindex < elen; eindex = eindex + 1 {
    let enow = e[eindex]
    let (product1, product0) = two_product_presplit(enow, b, bhi, blo)
    let (sum, hh_sum) = two_sum(q, product0)
    if hh_sum != 0.0 {
      h[hindex] = hh_sum
      hindex += 1
    }
    let (new_q, hh_fast) = fast_two_sum(product1, sum)
    q = new_q
    if hh_fast != 0.0 {
      h[hindex] = hh_fast
      hindex += 1
    }
  }
  if q != 0.0 || hindex == 0 {
    h[hindex] = q
    hindex += 1
  }
  hindex
}

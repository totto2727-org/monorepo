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
  e.iter().take(len).fold(init=0.0, fn(acc, x) { acc + x })
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
/// Drains the `tail` of either input (picking up where the merge stopped),
/// updating the running accumulator `q` and appending nonzero corrections.
fn drain_tail(
  source : Array[Double],
  start : Int,
  finish : Int,
  q_init : Double,
  h : Array[Double],
) -> Double {
  start
  .until(finish)
  .fold(init=q_init, fn(q, idx) {
    let (qnew, hh) = two_sum(q, source[idx])
    if hh != 0.0 {
      h.push(hh)
    }
    qnew
  })
}

///|
/// Shewchuk's "fast expansion sum, zero-elimination" merge of two
/// expansions `e[0..elen]` and `f[0..flen]` into a returned expansion of
/// length up to `elen + flen`. The output array is freshly allocated; the
/// inputs are not mutated.
///
/// §3.12 case 3: the merge body is a measured hot path (called many times
/// per `orient2d` adaptive step). The local accumulator `h` is built via
/// `push` and never escapes — it is returned to the caller as the only
/// reference, so the encapsulated mutation is invisible to the rest of the
/// program.
pub fn fast_expansion_sum_zeroelim(
  e : Array[Double],
  elen : Int,
  f : Array[Double],
  flen : Int,
) -> Array[Double] {
  let h : Array[Double] = []
  let mut eindex = 0
  let mut findex = 0
  let mut enow = e[0]
  let mut fnow = f[0]
  let mut q = if (fnow > enow) == (fnow > -enow) {
    eindex = 1
    enow
  } else {
    findex = 1
    fnow
  }
  // First merge step (if both inputs still have elements) uses `fast_two_sum`.
  if eindex < elen && findex < flen {
    enow = e[eindex]
    fnow = f[findex]
    let pick_e = (fnow > enow) == (fnow > -enow)
    let chosen = if pick_e { enow } else { fnow }
    let (qnew, hh) = fast_two_sum(chosen, q)
    if pick_e {
      eindex = eindex + 1
    } else {
      findex = findex + 1
    }
    q = qnew
    if hh != 0.0 {
      h.push(hh)
    }
    // Subsequent merge steps use `two_sum`.
    while eindex < elen && findex < flen {
      enow = e[eindex]
      fnow = f[findex]
      let pick_e2 = (fnow > enow) == (fnow > -enow)
      let chosen2 = if pick_e2 { enow } else { fnow }
      let (qnew2, hh2) = two_sum(q, chosen2)
      if pick_e2 {
        eindex = eindex + 1
      } else {
        findex = findex + 1
      }
      q = qnew2
      if hh2 != 0.0 {
        h.push(hh2)
      }
    }
  }
  q = drain_tail(e, eindex, elen, q, h)
  q = drain_tail(f, findex, flen, q, h)
  if q != 0.0 || h.length() == 0 {
    h.push(q)
  }
  h
}

///|
/// Shewchuk's "scale expansion, zero-elimination": multiplies expansion
/// `e[0..elen]` by scalar `b`. Returns a freshly allocated expansion; the
/// input is not mutated. Same hot-path justification as
/// `fast_expansion_sum_zeroelim`.
pub fn scale_expansion_zeroelim(
  e : Array[Double],
  elen : Int,
  b : Double,
) -> Array[Double] {
  let (bhi, blo) = split(b)
  let h : Array[Double] = []
  let (q0, hh0) = two_product_presplit(e[0], b, bhi, blo)
  if hh0 != 0.0 {
    h.push(hh0)
  }
  let final_q = (1)
    .until(elen)
    .fold(init=q0, fn(q, eindex) {
      let (product1, product0) = two_product_presplit(e[eindex], b, bhi, blo)
      let (sum, hh_sum) = two_sum(q, product0)
      if hh_sum != 0.0 {
        h.push(hh_sum)
      }
      let (new_q, hh_fast) = fast_two_sum(product1, sum)
      if hh_fast != 0.0 {
        h.push(hh_fast)
      }
      new_q
    })
  if final_q != 0.0 || h.length() == 0 {
    h.push(final_q)
  }
  h
}

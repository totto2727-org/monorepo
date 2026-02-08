///|
/// Returns a positive value if the coordinates `pa`, `pb`, and `pc` occur in counterclockwise order
/// (`pc` lies to the **left** of the directed line defined by coordinates `pa` and `pb`).
/// Returns a negative value if they occur in clockwise order (`pc` lies to the **right** of the directed line `pa, pb`).
/// Returns `0` if they are **collinear**.
pub fn[C : @type.Coord2DTrait] orient2d(pa : C, pb : C, pc : C) -> Double {
  let pa_x = pa.x()
  let pa_y = pa.y()
  let pb_x = pb.x()
  let pb_y = pb.y()
  let pc_x = pc.x()
  let pc_y = pc.y()
  let detleft = (pa_x - pc_x) * (pb_y - pc_y)
  let detright = (pa_y - pc_y) * (pb_x - pc_x)
  let det = detleft - detright

  // The errbound calculation was changed to require only one branch on the likely execution path.
  // This improves performance on modern processors as discussed by Ozaki et al in
  // https://doi.org/10.1007/s10543-015-0574-9
  let detsum = (detleft + detright).abs()
  let theta = 3.3306690621773722e-16
  let errbound = theta * detsum
  if det >= errbound || -det >= errbound {
    return det
  }
  orient2dadapt(pa_x, pa_y, pb_x, pb_y, pc_x, pc_y, detsum)
}

///|
fn orient2dadapt(
  pa_x : Double,
  pa_y : Double,
  pb_x : Double,
  pb_y : Double,
  pc_x : Double,
  pc_y : Double,
  detsum : Double,
) -> Double {
  let acx = pa_x - pc_x
  let bcx = pb_x - pc_x
  let acy = pa_y - pc_y
  let bcy = pb_y - pc_y
  let (detleft, detlefttail) = two_product(acx, bcy)
  let (detright, detrighttail) = two_product(acy, bcx)
  let (b3, b2, b1, b0) = two_two_diff(
    detleft, detlefttail, detright, detrighttail,
  )
  let b = [b0, b1, b2, b3]
  let mut det = estimate(b, 4)
  let errbound = CCWERRBOUND_B * detsum
  if det >= errbound || -det >= errbound {
    return det
  }
  let acxtail = two_diff_tail(pa_x, pc_x, acx)
  let bcxtail = two_diff_tail(pb_x, pc_x, bcx)
  let acytail = two_diff_tail(pa_y, pc_y, acy)
  let bcytail = two_diff_tail(pb_y, pc_y, bcy)
  if acxtail == 0.0 && acytail == 0.0 && bcxtail == 0.0 && bcytail == 0.0 {
    return det
  }
  let errbound = CCWERRBOUND_C * detsum + RESULTERRBOUND * det.abs()
  det += acx * bcytail + bcy * acxtail - (acy * bcxtail + bcx * acytail)
  if det >= errbound || -det >= errbound {
    return det
  }
  let (s1, s0) = two_product(acxtail, bcy)
  let (t1, t0) = two_product(acytail, bcx)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u = [u0, u1, u2, u3]
  let c1 = Array::make(8, 0.0)
  let c1length = fast_expansion_sum_zeroelim(b, 4, u, 4, c1)
  let (s1, s0) = two_product(acx, bcytail)
  let (t1, t0) = two_product(acy, bcxtail)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u = [u0, u1, u2, u3]
  let c2 = Array::make(12, 0.0)
  let c2length = fast_expansion_sum_zeroelim(c1, c1length, u, 4, c2)
  let (s1, s0) = two_product(acxtail, bcytail)
  let (t1, t0) = two_product(acytail, bcxtail)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u = [u0, u1, u2, u3]
  let d = Array::make(16, 0.0)
  let dlength = fast_expansion_sum_zeroelim(c2, c2length, u, 4, d)
  d[dlength - 1]
}

// Constants

///|
const SPLITTER : Double = 134_217_729.0

///|
const EPSILON : Double = 0.000_000_000_000_000_111_022_302_462_515_65

///|
const RESULTERRBOUND : Double = (3.0 + 8.0 * EPSILON) * EPSILON

///|
const CCWERRBOUND_B : Double = (2.0 + 12.0 * EPSILON) * EPSILON

///|
const CCWERRBOUND_C : Double = (9.0 + 64.0 * EPSILON) * EPSILON * EPSILON

///|
const O3DERRBOUND_A : Double = (7.0 + 56.0 * EPSILON) * EPSILON

///|
const O3DERRBOUND_B : Double = (3.0 + 28.0 * EPSILON) * EPSILON

///|
const O3DERRBOUND_C : Double = (26.0 + 288.0 * EPSILON) * EPSILON * EPSILON

///|
const ICCERRBOUND_A : Double = (10.0 + 96.0 * EPSILON) * EPSILON

///|
const ICCERRBOUND_B : Double = (4.0 + 48.0 * EPSILON) * EPSILON

///|
const ICCERRBOUND_C : Double = (44.0 + 576.0 * EPSILON) * EPSILON * EPSILON

///|
const ISPERRBOUND_A : Double = (16.0 + 224.0 * EPSILON) * EPSILON

///|
const ISPERRBOUND_B : Double = (5.0 + 72.0 * EPSILON) * EPSILON

///|
const ISPERRBOUND_C : Double = (71.0 + 1408.0 * EPSILON) * EPSILON * EPSILON

// Helpers

///|
fn estimate(e : Array[Double], len : Int) -> Double {
  let mut q = e[0]
  for i = 1; i < len; i = i + 1 {
    q += e[i]
  }
  q
}

///|
fn two_product(a : Double, b : Double) -> (Double, Double) {
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
fn split(a : Double) -> (Double, Double) {
  let c = SPLITTER * a
  let abig = c - a
  let ahi = c - abig
  let alo = a - ahi
  (ahi, alo)
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
fn two_two_diff(
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
fn two_one_diff(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (i, x0) = two_diff(a0, b)
  let (x2, x1) = two_sum(a1, i)
  (x2, x1, x0)
}

///|
fn two_diff(a : Double, b : Double) -> (Double, Double) {
  let x = a - b
  (x, two_diff_tail(a, b, x))
}

///|
fn two_diff_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = a - x
  let avirt = x + bvirt
  let bround = bvirt - b
  let around = a - avirt
  around + bround
}

///|
fn two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, two_sum_tail(a, b, x))
}

///|
fn two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  let avirt = x - bvirt
  let bround = b - bvirt
  let around = a - avirt
  around + bround
}

///|
fn fast_two_sum(a : Double, b : Double) -> (Double, Double) {
  let x = a + b
  (x, fast_two_sum_tail(a, b, x))
}

///|
fn fast_two_sum_tail(a : Double, b : Double, x : Double) -> Double {
  let bvirt = x - a
  b - bvirt
}

///|
fn square(a : Double) -> (Double, Double) {
  let x = a * a
  (x, square_tail(a, x))
}

///|
fn square_tail(a : Double, x : Double) -> Double {
  let (ahi, alo) = split(a)
  let err1 = x - ahi * ahi
  let err3 = err1 - (ahi + ahi) * alo
  alo * alo - err3
}

///|
fn two_one_sum(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (_i, x0) = two_sum(a0, b)
  let (x2, x1) = two_sum(a1, _i)
  (x2, x1, x0)
}

///|
fn two_two_sum(
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
fn two_one_product(
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
fn fast_expansion_sum_zeroelim(
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
fn scale_expansion_zeroelim(
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

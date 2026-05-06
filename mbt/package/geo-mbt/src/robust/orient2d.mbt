// Ported from georust/robust
// https://github.com/georust/robust/blob/master/src/lib.rs (orient2d)
// Reference also: mbt/package/geo/src/util/robust/orient2d.mbt — adapted to
// the geo-mbt concrete `Coord` type (no traits).

///|
/// Returns a positive value if `pa`, `pb`, `pc` occur in counter-clockwise
/// order (`pc` lies to the **left** of the directed line from `pa` to `pb`).
/// Returns a negative value if they occur clockwise. Returns `0` if collinear.
///
/// This is Shewchuk's adaptive precision predicate, robust against
/// floating-point error.
pub fn orient2d(pa : @type.Coord, pb : @type.Coord, pc : @type.Coord) -> Double {
  let pa_x = pa.x()
  let pa_y = pa.y()
  let pb_x = pb.x()
  let pb_y = pb.y()
  let pc_x = pc.x()
  let pc_y = pc.y()
  let detleft = (pa_x - pc_x) * (pb_y - pc_y)
  let detright = (pa_y - pc_y) * (pb_x - pc_x)
  let det = detleft - detright

  // The errbound calculation was changed to require only one branch on the
  // likely execution path (Ozaki et al. 2015).
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
  let c1 = fast_expansion_sum_zeroelim(b, 4, u, 4)
  let (s1, s0) = two_product(acx, bcytail)
  let (t1, t0) = two_product(acy, bcxtail)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u = [u0, u1, u2, u3]
  let c2 = fast_expansion_sum_zeroelim(c1, c1.length(), u, 4)
  let (s1, s0) = two_product(acxtail, bcytail)
  let (t1, t0) = two_product(acytail, bcxtail)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u = [u0, u1, u2, u3]
  let d = fast_expansion_sum_zeroelim(c2, c2.length(), u, 4)
  d[d.length() - 1]
}

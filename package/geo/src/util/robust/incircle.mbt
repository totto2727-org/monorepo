///|
/// incircle error bound A
let incircle_err_bound_a : Double = (10.0 + 96.0 * epsilon) * epsilon

///|
/// incircle error bound B
let incircle_err_bound_b : Double = (4.0 + 48.0 * epsilon) * epsilon

///|
/// incircle error bound C
let incircle_err_bound_c : Double = (44.0 + 576.0 * epsilon) * epsilon * epsilon

///|
/// Calculate sum of Expansion (a1, a0) and scalar b (x2, x1, x0)
fn two_one_sum(
  a1 : Double,
  a0 : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (i, x0) = two_sum(a0, b)
  let (x2, x1) = two_sum(a1, i)
  (x2, x1, x0)
}

///|
/// Calculate sum of Expansion (a1, a0) and Expansion (b1, b0) (x3, x2, x1, x0)
fn two_two_sum(
  a1 : Double,
  a0 : Double,
  b1 : Double,
  b0 : Double,
) -> (Double, Double, Double, Double) {
  let (j, r0, x0) = two_one_sum(a1, a0, b0)
  let (x3, x2, x1) = two_one_sum(j, r0, b1)
  (x3, x2, x1, x0)
}

///|
/// Adaptive precision calculation for incircle (internal function)
fn incircle_adapt(
  pa : @geojson.Position2D,
  pb : @geojson.Position2D,
  pc : @geojson.Position2D,
  pd : @geojson.Position2D,
  permanent : Double,
) -> Double {
  let adx = pa.x - pd.x
  let bdx = pb.x - pd.x
  let cdx = pc.x - pd.x
  let ady = pa.y - pd.y
  let bdy = pb.y - pd.y
  let cdy = pc.y - pd.y
  let (bdxcdy1, bdxcdy0) = two_product(bdx, cdy)
  let (cdxbdy1, cdxbdy0) = two_product(cdx, bdy)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
  let bc = Expansion::from_fixed_array([bc0, bc1, bc2, bc3])
  let axbc = bc.scale_expansion_zeroelim(adx)
  let axxbc = axbc.scale_expansion_zeroelim(adx)
  let aybc = bc.scale_expansion_zeroelim(ady)
  let ayybc = aybc.scale_expansion_zeroelim(ady)
  let adet = axxbc.fast_expansion_sum_zeroelim(ayybc)
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca = Expansion::from_fixed_array([ca0, ca1, ca2, ca3])
  let bxca = ca.scale_expansion_zeroelim(bdx)
  let bxxca = bxca.scale_expansion_zeroelim(bdx)
  let byca = ca.scale_expansion_zeroelim(bdy)
  let byyca = byca.scale_expansion_zeroelim(bdy)
  let bdet = bxxca.fast_expansion_sum_zeroelim(byyca)
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab = Expansion::from_fixed_array([ab0, ab1, ab2, ab3])
  let cxab = ab.scale_expansion_zeroelim(cdx)
  let cxxab = cxab.scale_expansion_zeroelim(cdx)
  let cyab = ab.scale_expansion_zeroelim(cdy)
  let cyyab = cyab.scale_expansion_zeroelim(cdy)
  let cdet = cxxab.fast_expansion_sum_zeroelim(cyyab)
  let fin1 = adet
    .fast_expansion_sum_zeroelim(bdet)
    .fast_expansion_sum_zeroelim(cdet)
  let det = fin1.estimate()
  let errbound1 = incircle_err_bound_b * permanent
  if det >= errbound1 || -det >= errbound1 {
    return det
  }
  let adxtail = two_diff_tail(pa.x, pd.x, adx)
  let adytail = two_diff_tail(pa.y, pd.y, ady)
  let bdxtail = two_diff_tail(pb.x, pd.x, bdx)
  let bdytail = two_diff_tail(pb.y, pd.y, bdy)
  let cdxtail = two_diff_tail(pc.x, pd.x, cdx)
  let cdytail = two_diff_tail(pc.y, pd.y, cdy)
  if adxtail == 0.0 &&
    bdxtail == 0.0 &&
    cdxtail == 0.0 &&
    adytail == 0.0 &&
    bdytail == 0.0 &&
    cdytail == 0.0 {
    return det
  }
  let errbound2 = incircle_err_bound_c * permanent + result_err_bound * abs(det)
  let det = det +
    (adx * adx + ady * ady) *
    (bdx * cdytail + cdy * bdxtail - (bdy * cdxtail + cdx * bdytail)) +
    2.0 * (adx * adxtail + ady * adytail) * (bdx * cdy - bdy * cdx) +
    (bdx * bdx + bdy * bdy) *
    (cdx * adytail + ady * cdxtail - (cdy * adxtail + adx * cdytail)) +
    2.0 * (bdx * bdxtail + bdy * bdytail) * (cdx * ady - cdy * adx) +
    (cdx * cdx + cdy * cdy) *
    (adx * bdytail + bdy * adxtail - (ady * bdxtail + bdx * adytail)) +
    2.0 * (cdx * cdxtail + cdy * cdytail) * (adx * bdy - ady * bdx)
  if det >= errbound2 || -det >= errbound2 {
    return det
  }
  let aa = if bdxtail != 0.0 ||
    bdytail != 0.0 ||
    cdxtail != 0.0 ||
    cdytail != 0.0 {
    let (adxadx1, adxadx0) = square(adx)
    let (adyady1, adyady0) = square(ady)
    let (aa3, aa2, aa1, aa0) = two_two_sum(adxadx1, adxadx0, adyady1, adyady0)
    Expansion::from_fixed_array([aa0, aa1, aa2, aa3])
  } else {
    Expansion::from_fixed_array([])
  }
  let bb = if cdxtail != 0.0 ||
    cdytail != 0.0 ||
    adxtail != 0.0 ||
    adytail != 0.0 {
    let (bdxbdx1, bdxbdx0) = square(bdx)
    let (bdybdy1, bdybdy0) = square(bdy)
    let (bb3, bb2, bb1, bb0) = two_two_sum(bdxbdx1, bdxbdx0, bdybdy1, bdybdy0)
    Expansion::from_fixed_array([bb0, bb1, bb2, bb3])
  } else {
    Expansion::from_fixed_array([])
  }
  let cc = if adxtail != 0.0 ||
    adytail != 0.0 ||
    bdxtail != 0.0 ||
    bdytail != 0.0 {
    let (cdxcdx1, cdxcdx0) = square(cdx)
    let (cdycdy1, cdycdy0) = square(cdy)
    let (cc3, cc2, cc1, cc0) = two_two_sum(cdxcdx1, cdxcdx0, cdycdy1, cdycdy0)
    Expansion::from_fixed_array([cc0, cc1, cc2, cc3])
  } else {
    Expansion::from_fixed_array([])
  }
  let fin_final = if adxtail != 0.0 {
    let temp16a = bc
      .scale_expansion_zeroelim(adxtail)
      .scale_expansion_zeroelim(2.0 * adx)
    let temp16b = cc
      .scale_expansion_zeroelim(adxtail)
      .scale_expansion_zeroelim(bdy)
    let temp16c = bb
      .scale_expansion_zeroelim(adxtail)
      .scale_expansion_zeroelim(-cdy)
    fin1
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin1
  }
  let fin_final = if adytail != 0.0 {
    let temp16a = bc
      .scale_expansion_zeroelim(adytail)
      .scale_expansion_zeroelim(2.0 * ady)
    let temp16b = bb
      .scale_expansion_zeroelim(adytail)
      .scale_expansion_zeroelim(cdx)
    let temp16c = cc
      .scale_expansion_zeroelim(adytail)
      .scale_expansion_zeroelim(-bdx)
    fin_final
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin_final
  }
  let fin_final = if bdxtail != 0.0 {
    let temp16a = ca
      .scale_expansion_zeroelim(bdxtail)
      .scale_expansion_zeroelim(2.0 * bdx)
    let temp16b = aa
      .scale_expansion_zeroelim(bdxtail)
      .scale_expansion_zeroelim(cdy)
    let temp16c = cc
      .scale_expansion_zeroelim(bdxtail)
      .scale_expansion_zeroelim(-ady)
    fin_final
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin_final
  }
  let fin_final = if bdytail != 0.0 {
    let temp16a = ca
      .scale_expansion_zeroelim(bdytail)
      .scale_expansion_zeroelim(2.0 * bdy)
    let temp16b = cc
      .scale_expansion_zeroelim(bdytail)
      .scale_expansion_zeroelim(adx)
    let temp16c = aa
      .scale_expansion_zeroelim(bdytail)
      .scale_expansion_zeroelim(-cdx)
    fin_final
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin_final
  }
  let fin_final = if cdxtail != 0.0 {
    let temp16a = ab
      .scale_expansion_zeroelim(cdxtail)
      .scale_expansion_zeroelim(2.0 * cdx)
    let temp16b = bb
      .scale_expansion_zeroelim(cdxtail)
      .scale_expansion_zeroelim(ady)
    let temp16c = aa
      .scale_expansion_zeroelim(cdxtail)
      .scale_expansion_zeroelim(-bdy)
    fin_final
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin_final
  }
  let fin_final = if cdytail != 0.0 {
    let temp16a = ab
      .scale_expansion_zeroelim(cdytail)
      .scale_expansion_zeroelim(2.0 * cdy)
    let temp16b = aa
      .scale_expansion_zeroelim(cdytail)
      .scale_expansion_zeroelim(bdx)
    let temp16c = bb
      .scale_expansion_zeroelim(cdytail)
      .scale_expansion_zeroelim(-adx)
    fin_final
    .fast_expansion_sum_zeroelim(temp16a)
    .fast_expansion_sum_zeroelim(temp16b)
    .fast_expansion_sum_zeroelim(temp16c)
  } else {
    fin_final
  }
  fin_final.data[fin_final.length - 1]
}

///|
/// 2D incircle test
///
/// Determines if point pd is inside the circumcircle of the triangle defined by three points (pa, pb, pc) arranged in counter-clockwise order.
/// - Positive: pd is inside the circle
/// - Negative: pd is outside the circle
/// - 0: pd is on the circle boundary
pub fn incircle(
  pa : @geojson.Position2D,
  pb : @geojson.Position2D,
  pc : @geojson.Position2D,
  pd : @geojson.Position2D,
) -> Double {
  let adx = pa.x - pd.x
  let bdx = pb.x - pd.x
  let cdx = pc.x - pd.x
  let ady = pa.y - pd.y
  let bdy = pb.y - pd.y
  let cdy = pc.y - pd.y
  let bdxcdy = bdx * cdy
  let cdxbdy = cdx * bdy
  let alift = adx * adx + ady * ady
  let cdxady = cdx * ady
  let adxcdy = adx * cdy
  let blift = bdx * bdx + bdy * bdy
  let adxbdy = adx * bdy
  let bdxady = bdx * ady
  let clift = cdx * cdx + cdy * cdy
  let det = alift * (bdxcdy - cdxbdy) +
    blift * (cdxady - adxcdy) +
    clift * (adxbdy - bdxady)
  let permanent = (abs(bdxcdy) + abs(cdxbdy)) * alift +
    (abs(cdxady) + abs(adxcdy)) * blift +
    (abs(adxbdy) + abs(bdxady)) * clift
  let errbound = incircle_err_bound_a * permanent
  if det > errbound || -det > errbound {
    det
  } else {
    incircle_adapt(pa, pb, pc, pd, permanent)
  }
}

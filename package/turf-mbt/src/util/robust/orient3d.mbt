///|
/// orient3d error bound A
let orient3d_err_bound_a : Double = (7.0 + 56.0 * epsilon) * epsilon

///|
/// orient3d error bound B
let orient3d_err_bound_b : Double = (3.0 + 28.0 * epsilon) * epsilon

///|
/// orient3d error bound C
let orient3d_err_bound_c : Double = (26.0 + 288.0 * epsilon) * epsilon * epsilon

///|
/// Adaptive precision calculation for orient3d (internal function)
fn orient3d_adapt(
  pa : @geojson.Position3D,
  pb : @geojson.Position3D,
  pc : @geojson.Position3D,
  pd : @geojson.Position3D,
  permanent : Double,
) -> Double {
  // Calculate coordinate differences
  let adx = pa.x - pd.x
  let bdx = pb.x - pd.x
  let cdx = pc.x - pd.x
  let ady = pa.y - pd.y
  let bdy = pb.y - pd.y
  let cdy = pc.y - pd.y
  let adz = pa.z - pd.z
  let bdz = pb.z - pd.z
  let cdz = pc.z - pd.z
  let (bdxcdy1, bdxcdy0) = two_product(bdx, cdy)
  let (cdxbdy1, cdxbdy0) = two_product(cdx, bdy)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
  let bc = Expansion::from_fixed_array([bc0, bc1, bc2, bc3])
  let adet = bc.scale_expansion_zeroelim(adz)
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca = Expansion::from_fixed_array([ca0, ca1, ca2, ca3])
  let bdet = ca.scale_expansion_zeroelim(bdz)
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab = Expansion::from_fixed_array([ab0, ab1, ab2, ab3])
  let cdet = ab.scale_expansion_zeroelim(cdz)
  let fin1 = adet
    .fast_expansion_sum_zeroelim(bdet)
    .fast_expansion_sum_zeroelim(cdet)
  let det = fin1.estimate()

  // Check error bounds
  let errbound = orient3d_err_bound_b * permanent
  if det >= errbound || -det >= errbound {
    return det
  }
  let adxtail = two_diff_tail(pa.x, pd.x, adx)
  let bdxtail = two_diff_tail(pb.x, pd.x, bdx)
  let cdxtail = two_diff_tail(pc.x, pd.x, cdx)
  let adytail = two_diff_tail(pa.y, pd.y, ady)
  let bdytail = two_diff_tail(pb.y, pd.y, bdy)
  let cdytail = two_diff_tail(pc.y, pd.y, cdy)
  let adztail = two_diff_tail(pa.z, pd.z, adz)
  let bdztail = two_diff_tail(pb.z, pd.z, bdz)
  let cdztail = two_diff_tail(pc.z, pd.z, cdz)
  if adxtail == 0.0 &&
    adytail == 0.0 &&
    adztail == 0.0 &&
    bdxtail == 0.0 &&
    bdytail == 0.0 &&
    bdztail == 0.0 &&
    cdxtail == 0.0 &&
    cdytail == 0.0 &&
    cdztail == 0.0 {
    return det
  }
  let errbound_c = orient3d_err_bound_c * permanent +
    result_err_bound * abs(det)
  let det = det +
    (
      adx * (bdy * cdztail + cdz * bdytail) -
      ady * (bdx * cdztail + cdz * bdxtail) +
      adz * (bdx * cdytail + cdy * bdxtail)
    ) -
    (
      bdx * (ady * cdztail + cdz * adytail) -
      bdy * (adx * cdztail + cdz * adxtail) +
      bdz * (adx * cdytail + cdy * adxtail)
    ) +
    (
      cdx * (ady * bdztail + bdz * adytail) -
      cdy * (adx * bdztail + bdz * adxtail) +
      cdz * (adx * bdytail + bdy * adxtail)
    )
  if det >= errbound_c || -det >= errbound_c {
    return det
  }
  let atb = if adztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
    Expansion::from_fixed_array([t0, t1, t2, t3])
  } else {
    Expansion::from_fixed_array([])
  }
  let atc = if adztail != 0.0 {
    let (s3, s2, s1, s0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
    Expansion::from_fixed_array([s0, s1, s2, s3])
  } else {
    Expansion::from_fixed_array([])
  }
  let btc = if bdztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
    Expansion::from_fixed_array([t0, t1, t2, t3])
  } else {
    Expansion::from_fixed_array([])
  }
  let bta = if bdztail != 0.0 {
    let (s3, s2, s1, s0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
    Expansion::from_fixed_array([s0, s1, s2, s3])
  } else {
    Expansion::from_fixed_array([])
  }
  let cta = if cdztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
    Expansion::from_fixed_array([t0, t1, t2, t3])
  } else {
    Expansion::from_fixed_array([])
  }
  let ctb = if cdztail != 0.0 {
    let (s3, s2, s1, s0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
    Expansion::from_fixed_array([s0, s1, s2, s3])
  } else {
    Expansion::from_fixed_array([])
  }
  let (u3, u2, u1, u0) = two_one_product(bdy, cdztail, adx)
  let (v3, v2, v1, v0) = two_one_product(cdz, bdytail, adx)
  let temp8a = Expansion::from_fixed_array([u0, u1, u2, u3]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0, v1, v2, v3]),
  )
  let (u3_1, u2_1, u1_1, u0_1) = two_one_product(bdx, cdztail, -ady)
  let (v3_1, v2_1, v1_1, v0_1) = two_one_product(cdz, bdxtail, -ady)
  let temp8b = Expansion::from_fixed_array([u0_1, u1_1, u2_1, u3_1]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_1, v1_1, v2_1, v3_1]),
  )
  let (u3_2, u2_2, u1_2, u0_2) = two_one_product(bdx, cdytail, adz)
  let (v3_2, v2_2, v1_2, v0_2) = two_one_product(cdy, bdxtail, adz)
  let temp8c = Expansion::from_fixed_array([u0_2, u1_2, u2_2, u3_2]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_2, v1_2, v2_2, v3_2]),
  )
  let temp24a = temp8a
    .fast_expansion_sum_zeroelim(temp8b)
    .fast_expansion_sum_zeroelim(temp8c)
  let (u3_3, u2_3, u1_3, u0_3) = two_one_product(ady, cdztail, -bdx)
  let (v3_3, v2_3, v1_3, v0_3) = two_one_product(cdz, adytail, -bdx)
  let temp8a_1 = Expansion::from_fixed_array([u0_3, u1_3, u2_3, u3_3]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_3, v1_3, v2_3, v3_3]),
  )
  let (u3_4, u2_4, u1_4, u0_4) = two_one_product(adx, cdztail, bdy)
  let (v3_4, v2_4, v1_4, v0_4) = two_one_product(cdz, adxtail, bdy)
  let temp8b_1 = Expansion::from_fixed_array([u0_4, u1_4, u2_4, u3_4]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_4, v1_4, v2_4, v3_4]),
  )
  let (u3_5, u2_5, u1_5, u0_5) = two_one_product(adx, cdytail, -bdz)
  let (v3_5, v2_5, v1_5, v0_5) = two_one_product(cdy, adxtail, -bdz)
  let temp8c_1 = Expansion::from_fixed_array([u0_5, u1_5, u2_5, u3_5]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_5, v1_5, v2_5, v3_5]),
  )
  let temp24b = temp8a_1
    .fast_expansion_sum_zeroelim(temp8b_1)
    .fast_expansion_sum_zeroelim(temp8c_1)
  let (u3_6, u2_6, u1_6, u0_6) = two_one_product(ady, bdztail, cdx)
  let (v3_6, v2_6, v1_6, v0_6) = two_one_product(bdz, adytail, cdx)
  let temp8a_2 = Expansion::from_fixed_array([u0_6, u1_6, u2_6, u3_6]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_6, v1_6, v2_6, v3_6]),
  )
  let (u3_7, u2_7, u1_7, u0_7) = two_one_product(adx, bdztail, -cdy)
  let (v3_7, v2_7, v1_7, v0_7) = two_one_product(bdz, adxtail, -cdy)
  let temp8b_2 = Expansion::from_fixed_array([u0_7, u1_7, u2_7, u3_7]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_7, v1_7, v2_7, v3_7]),
  )
  let (u3_8, u2_8, u1_8, u0_8) = two_one_product(adx, bdytail, cdz)
  let (v3_8, v2_8, v1_8, v0_8) = two_one_product(bdy, adxtail, cdz)
  let temp8c_2 = Expansion::from_fixed_array([u0_8, u1_8, u2_8, u3_8]).fast_expansion_sum_zeroelim(
    Expansion::from_fixed_array([v0_8, v1_8, v2_8, v3_8]),
  )
  let temp24c = temp8a_2
    .fast_expansion_sum_zeroelim(temp8b_2)
    .fast_expansion_sum_zeroelim(temp8c_2)
  let temp72 = temp24a
    .fast_expansion_sum_zeroelim(temp24b)
    .fast_expansion_sum_zeroelim(temp24c)
  let fin_final = fin1.fast_expansion_sum_zeroelim(temp72)
  let fin_final = if adztail != 0.0 {
    let w = atb.scale_expansion_zeroelim(adztail)
    let w2 = atc.scale_expansion_zeroelim(adztail)
    fin_final.fast_expansion_sum_zeroelim(w).fast_expansion_sum_zeroelim(w2)
  } else {
    fin_final
  }
  let fin_final = if bdztail != 0.0 {
    let w = btc.scale_expansion_zeroelim(bdztail)
    let w2 = bta.scale_expansion_zeroelim(bdztail)
    fin_final.fast_expansion_sum_zeroelim(w).fast_expansion_sum_zeroelim(w2)
  } else {
    fin_final
  }
  let fin_final = if cdztail != 0.0 {
    let w = cta.scale_expansion_zeroelim(cdztail)
    let w2 = ctb.scale_expansion_zeroelim(cdztail)
    fin_final.fast_expansion_sum_zeroelim(w).fast_expansion_sum_zeroelim(w2)
  } else {
    fin_final
  }
  fin_final.data[fin_final.length - 1]
}

///|
/// 3D orientation test
///
/// Determines the orientation of four points (pa, pb, pc, pd).
/// - Positive: pd is outside the plane pa-pb-pc
/// - Negative: pd is inside the plane pa-pb-pc
/// - 0: Coplanar
pub fn orient3d(
  pa : @geojson.Position3D,
  pb : @geojson.Position3D,
  pc : @geojson.Position3D,
  pd : @geojson.Position3D,
) -> Double {
  // Calculate coordinate differences
  let adx = pa.x - pd.x
  let bdx = pb.x - pd.x
  let cdx = pc.x - pd.x
  let ady = pa.y - pd.y
  let bdy = pb.y - pd.y
  let cdy = pc.y - pd.y
  let adz = pa.z - pd.z
  let bdz = pb.z - pd.z
  let cdz = pc.z - pd.z

  // Approximate determinant calculation
  let bdxcdy = bdx * cdy
  let cdxbdy = cdx * bdy
  let cdxady = cdx * ady
  let adxcdy = adx * cdy
  let adxbdy = adx * bdy
  let bdxady = bdx * ady
  let det = adz * (bdxcdy - cdxbdy) +
    bdz * (cdxady - adxcdy) +
    cdz * (adxbdy - bdxady)

  // Calculate error bound
  let permanent = (abs(bdxcdy) + abs(cdxbdy)) * abs(adz) +
    (abs(cdxady) + abs(adxcdy)) * abs(bdz) +
    (abs(adxbdy) + abs(bdxady)) * abs(cdz)
  let errbound = orient3d_err_bound_a * permanent

  // Check if precision is needed
  if det > errbound || -det > errbound {
    det
  } else {
    orient3d_adapt(pa, pb, pc, pd, permanent)
  }
}

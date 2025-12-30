///|
/// orient3d 誤差境界 A
let orient3d_err_bound_a : Double = (7.0 + 56.0 * epsilon) * epsilon

///|
/// orient3d 誤差境界 B
let orient3d_err_bound_b : Double = (3.0 + 28.0 * epsilon) * epsilon

///|
/// orient3d 誤差境界 C
let orient3d_err_bound_c : Double = (26.0 + 288.0 * epsilon) * epsilon * epsilon

///|
/// orient3d の適応的精度計算（内部関数）
fn orient3d_adapt(
  pa : Coord3D,
  pb : Coord3D,
  pc : Coord3D,
  pd : Coord3D,
  permanent : Double,
) -> Double {
  // 座標の差分計算
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
  let bc : FixedArray[Double] = [bc0, bc1, bc2, bc3]
  let adet : FixedArray[Double] = FixedArray::make(8, 0.0)
  let alen = scale_expansion_zeroelim(bc, 4, adz, adet)
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca : FixedArray[Double] = [ca0, ca1, ca2, ca3]
  let bdet : FixedArray[Double] = FixedArray::make(8, 0.0)
  let blen = scale_expansion_zeroelim(ca, 4, bdz, bdet)
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab : FixedArray[Double] = [ab0, ab1, ab2, ab3]
  let cdet : FixedArray[Double] = FixedArray::make(8, 0.0)
  let clen = scale_expansion_zeroelim(ab, 4, cdz, cdet)
  let abdet : FixedArray[Double] = FixedArray::make(16, 0.0)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let fin1 : FixedArray[Double] = FixedArray::make(192, 0.0)
  let mut finlen = fast_expansion_sum_zeroelim(abdet, ablen, cdet, clen, fin1)
  let det = estimate(fin1, finlen)

  // 誤差境界のチェック
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
  let fin2 : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let u : FixedArray[Double] = FixedArray::make(4, 0.0)
  let v : FixedArray[Double] = FixedArray::make(4, 0.0)
  let mut atblen = 0
  let mut atclen = 0
  let mut btclen = 0
  let mut btalen = 0
  let mut ctalen = 0
  let mut ctblen = 0
  let atb : FixedArray[Double] = FixedArray::make(4, 0.0)
  let atc : FixedArray[Double] = FixedArray::make(4, 0.0)
  let btc : FixedArray[Double] = FixedArray::make(4, 0.0)
  let bta : FixedArray[Double] = FixedArray::make(4, 0.0)
  let cta : FixedArray[Double] = FixedArray::make(4, 0.0)
  let ctb : FixedArray[Double] = FixedArray::make(4, 0.0)
  if adztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
    atb[0] = t0
    atb[1] = t1
    atb[2] = t2
    atb[3] = t3
    atblen = 4
    let (s3, s2, s1, s0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
    atc[0] = s0
    atc[1] = s1
    atc[2] = s2
    atc[3] = s3
    atclen = 4
  }
  if bdztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
    btc[0] = t0
    btc[1] = t1
    btc[2] = t2
    btc[3] = t3
    btclen = 4
    let (s3, s2, s1, s0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
    bta[0] = s0
    bta[1] = s1
    bta[2] = s2
    bta[3] = s3
    btalen = 4
  }
  if cdztail != 0.0 {
    let (t3, t2, t1, t0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
    cta[0] = t0
    cta[1] = t1
    cta[2] = t2
    cta[3] = t3
    ctalen = 4
    let (s3, s2, s1, s0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
    ctb[0] = s0
    ctb[1] = s1
    ctb[2] = s2
    ctb[3] = s3
    ctblen = 4
  }
  let w : FixedArray[Double] = FixedArray::make(16, 0.0)
  let (u3, u2, u1, u0) = two_one_product(bdy, cdztail, adx)
  u[0] = u0
  u[1] = u1
  u[2] = u2
  u[3] = u3
  let (v3, v2, v1, v0) = two_one_product(cdz, bdytail, adx)
  v[0] = v0
  v[1] = v1
  v[2] = v2
  v[3] = v3
  let temp8a : FixedArray[Double] = FixedArray::make(8, 0.0)
  let mut temp8len = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8a)
  let (u3_1, u2_1, u1_1, u0_1) = two_one_product(bdx, cdztail, -ady)
  u[0] = u0_1
  u[1] = u1_1
  u[2] = u2_1
  u[3] = u3_1
  let (v3_1, v2_1, v1_1, v0_1) = two_one_product(cdz, bdxtail, -ady)
  v[0] = v0_1
  v[1] = v1_1
  v[2] = v2_1
  v[3] = v3_1
  let temp8b : FixedArray[Double] = FixedArray::make(8, 0.0)
  let mut temp8len2 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8b)
  let (u3_2, u2_2, u1_2, u0_2) = two_one_product(bdx, cdytail, adz)
  u[0] = u0_2
  u[1] = u1_2
  u[2] = u2_2
  u[3] = u3_2
  let (v3_2, v2_2, v1_2, v0_2) = two_one_product(cdy, bdxtail, adz)
  v[0] = v0_2
  v[1] = v1_2
  v[2] = v2_2
  v[3] = v3_2
  let temp8c : FixedArray[Double] = FixedArray::make(8, 0.0)
  let mut temp8len3 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8c)
  let temp16a : FixedArray[Double] = FixedArray::make(16, 0.0)
  let mut temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8len, temp8b, temp8len2, temp16a,
  )
  let temp24a : FixedArray[Double] = FixedArray::make(24, 0.0)
  let temp24len = fast_expansion_sum_zeroelim(
    temp16a, temp16len, temp8c, temp8len3, temp24a,
  )
  let (u3_3, u2_3, u1_3, u0_3) = two_one_product(ady, cdztail, -bdx)
  u[0] = u0_3
  u[1] = u1_3
  u[2] = u2_3
  u[3] = u3_3
  let (v3_3, v2_3, v1_3, v0_3) = two_one_product(cdz, adytail, -bdx)
  v[0] = v0_3
  v[1] = v1_3
  v[2] = v2_3
  v[3] = v3_3
  temp8len = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8a)
  let (u3_4, u2_4, u1_4, u0_4) = two_one_product(adx, cdztail, bdy)
  u[0] = u0_4
  u[1] = u1_4
  u[2] = u2_4
  u[3] = u3_4
  let (v3_4, v2_4, v1_4, v0_4) = two_one_product(cdz, adxtail, bdy)
  v[0] = v0_4
  v[1] = v1_4
  v[2] = v2_4
  v[3] = v3_4
  temp8len2 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8b)
  let (u3_5, u2_5, u1_5, u0_5) = two_one_product(adx, cdytail, -bdz)
  u[0] = u0_5
  u[1] = u1_5
  u[2] = u2_5
  u[3] = u3_5
  let (v3_5, v2_5, v1_5, v0_5) = two_one_product(cdy, adxtail, -bdz)
  v[0] = v0_5
  v[1] = v1_5
  v[2] = v2_5
  v[3] = v3_5
  temp8len3 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8c)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8len, temp8b, temp8len2, temp16a,
  )
  let temp24b : FixedArray[Double] = FixedArray::make(24, 0.0)
  let temp24len2 = fast_expansion_sum_zeroelim(
    temp16a, temp16len, temp8c, temp8len3, temp24b,
  )
  let (u3_6, u2_6, u1_6, u0_6) = two_one_product(ady, bdztail, cdx)
  u[0] = u0_6
  u[1] = u1_6
  u[2] = u2_6
  u[3] = u3_6
  let (v3_6, v2_6, v1_6, v0_6) = two_one_product(bdz, adytail, cdx)
  v[0] = v0_6
  v[1] = v1_6
  v[2] = v2_6
  v[3] = v3_6
  temp8len = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8a)
  let (u3_7, u2_7, u1_7, u0_7) = two_one_product(adx, bdztail, -cdy)
  u[0] = u0_7
  u[1] = u1_7
  u[2] = u2_7
  u[3] = u3_7
  let (v3_7, v2_7, v1_7, v0_7) = two_one_product(bdz, adxtail, -cdy)
  v[0] = v0_7
  v[1] = v1_7
  v[2] = v2_7
  v[3] = v3_7
  temp8len2 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8b)
  let (u3_8, u2_8, u1_8, u0_8) = two_one_product(adx, bdytail, cdz)
  u[0] = u0_8
  u[1] = u1_8
  u[2] = u2_8
  u[3] = u3_8
  let (v3_8, v2_8, v1_8, v0_8) = two_one_product(bdy, adxtail, cdz)
  v[0] = v0_8
  v[1] = v1_8
  v[2] = v2_8
  v[3] = v3_8
  temp8len3 = fast_expansion_sum_zeroelim(u, 4, v, 4, temp8c)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8len, temp8b, temp8len2, temp16a,
  )
  let temp24c : FixedArray[Double] = FixedArray::make(24, 0.0)
  let temp24len3 = fast_expansion_sum_zeroelim(
    temp16a, temp16len, temp8c, temp8len3, temp24c,
  )
  let temp48 : FixedArray[Double] = FixedArray::make(48, 0.0)
  let temp48len = fast_expansion_sum_zeroelim(
    temp24a, temp24len, temp24b, temp24len2, temp48,
  )
  let temp72 : FixedArray[Double] = FixedArray::make(72, 0.0)
  let temp72len = fast_expansion_sum_zeroelim(
    temp48, temp48len, temp24c, temp24len3, temp72,
  )
  finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp72, temp72len, fin2)
  if adztail != 0.0 {
    let wlen = scale_expansion_zeroelim(atb, atblen, adztail, w)
    let finlen2 = fast_expansion_sum_zeroelim(fin2, finlen, w, wlen, fin1)
    let wlen2 = scale_expansion_zeroelim(atc, atclen, adztail, w)
    finlen = fast_expansion_sum_zeroelim(fin1, finlen2, w, wlen2, fin2)
  }
  if bdztail != 0.0 {
    let wlen = scale_expansion_zeroelim(btc, btclen, bdztail, w)
    let finlen2 = fast_expansion_sum_zeroelim(fin2, finlen, w, wlen, fin1)
    let wlen2 = scale_expansion_zeroelim(bta, btalen, bdztail, w)
    finlen = fast_expansion_sum_zeroelim(fin1, finlen2, w, wlen2, fin2)
  }
  if cdztail != 0.0 {
    let wlen = scale_expansion_zeroelim(cta, ctalen, cdztail, w)
    let finlen2 = fast_expansion_sum_zeroelim(fin2, finlen, w, wlen, fin1)
    let wlen2 = scale_expansion_zeroelim(ctb, ctblen, cdztail, w)
    finlen = fast_expansion_sum_zeroelim(fin1, finlen2, w, wlen2, fin2)
  }
  fin2[finlen - 1]
}

///|
/// 3D向きテスト
///
/// 4点(pa, pb, pc, pd)の向きを判定する。
/// - 正の値: pdは面pa-pb-pcの外側
/// - 負の値: pdは面pa-pb-pcの内側
/// - 0: 4点が同一平面上
pub fn orient3d(
  pa : @geojson.Position,
  pb : @geojson.Position,
  pc : @geojson.Position,
  pd : @geojson.Position,
) -> Double raise {
  // 座標の差分計算
  let pa = to_coord3d(pa)
  let pb = to_coord3d(pb)
  let pc = to_coord3d(pc)
  let pd = to_coord3d(pd)
  let adx = pa.x - pd.x
  let bdx = pb.x - pd.x
  let cdx = pc.x - pd.x
  let ady = pa.y - pd.y
  let bdy = pb.y - pd.y
  let cdy = pc.y - pd.y
  let adz = pa.z - pd.z
  let bdz = pb.z - pd.z
  let cdz = pc.z - pd.z

  // 近似行列式計算
  let bdxcdy = bdx * cdy
  let cdxbdy = cdx * bdy
  let cdxady = cdx * ady
  let adxcdy = adx * cdy
  let adxbdy = adx * bdy
  let bdxady = bdx * ady
  let det = adz * (bdxcdy - cdxbdy) +
    bdz * (cdxady - adxcdy) +
    cdz * (adxbdy - bdxady)

  // 誤差境界の計算
  let permanent = (abs(bdxcdy) + abs(cdxbdy)) * abs(adz) +
    (abs(cdxady) + abs(adxcdy)) * abs(bdz) +
    (abs(adxbdy) + abs(bdxady)) * abs(cdz)
  let errbound = orient3d_err_bound_a * permanent

  // 精度が必要か確認
  if det > errbound || -det > errbound {
    det
  } else {
    orient3d_adapt(pa, pb, pc, pd, permanent)
  }
}

///|
/// incircle 誤差境界 A
let incircle_err_bound_a : Double = (10.0 + 96.0 * epsilon) * epsilon

///|
/// incircle 誤差境界 B
let incircle_err_bound_b : Double = (4.0 + 48.0 * epsilon) * epsilon

///|
/// incircle 誤差境界 C
let incircle_err_bound_c : Double = (44.0 + 576.0 * epsilon) * epsilon * epsilon

///|
/// Expansion (a1, a0) とスカラ b の和を計算する (x2, x1, x0)
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
/// Expansion (a1, a0) と Expansion (b1, b0) の和を計算する (x3, x2, x1, x0)
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
/// incircle の適応的精度計算（内部関数）
fn incircleadapt(
  pa : Coord,
  pb : Coord,
  pc : Coord,
  pd : Coord,
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
  let bc : FixedArray[Double] = [bc0, bc1, bc2, bc3]
  let axbc : FixedArray[Double] = FixedArray::make(8, 0.0)
  let axbc_length = scale_expansion_zeroelim(bc, 4, adx, axbc)
  let axxbc : FixedArray[Double] = FixedArray::make(16, 0.0)
  let axxbc_length = scale_expansion_zeroelim(axbc, axbc_length, adx, axxbc)
  let aybc : FixedArray[Double] = FixedArray::make(8, 0.0)
  let aybc_length = scale_expansion_zeroelim(bc, 4, ady, aybc)
  let ayybc : FixedArray[Double] = FixedArray::make(16, 0.0)
  let ayybc_length = scale_expansion_zeroelim(aybc, aybc_length, ady, ayybc)
  let adet : FixedArray[Double] = FixedArray::make(32, 0.0)
  let alen = fast_expansion_sum_zeroelim(
    axxbc, axxbc_length, ayybc, ayybc_length, adet,
  )
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca : FixedArray[Double] = [ca0, ca1, ca2, ca3]
  let bxca : FixedArray[Double] = FixedArray::make(8, 0.0)
  let bxca_length = scale_expansion_zeroelim(ca, 4, bdx, bxca)
  let bxxca : FixedArray[Double] = FixedArray::make(16, 0.0)
  let bxxca_length = scale_expansion_zeroelim(bxca, bxca_length, bdx, bxxca)
  let byca : FixedArray[Double] = FixedArray::make(8, 0.0)
  let byca_length = scale_expansion_zeroelim(ca, 4, bdy, byca)
  let byyca : FixedArray[Double] = FixedArray::make(16, 0.0)
  let byyca_length = scale_expansion_zeroelim(byca, byca_length, bdy, byyca)
  let bdet : FixedArray[Double] = FixedArray::make(32, 0.0)
  let blen = fast_expansion_sum_zeroelim(
    bxxca, bxxca_length, byyca, byyca_length, bdet,
  )
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab : FixedArray[Double] = [ab0, ab1, ab2, ab3]
  let cxab : FixedArray[Double] = FixedArray::make(8, 0.0)
  let cxab_length = scale_expansion_zeroelim(ab, 4, cdx, cxab)
  let cxxab : FixedArray[Double] = FixedArray::make(16, 0.0)
  let cxxab_length = scale_expansion_zeroelim(cxab, cxab_length, cdx, cxxab)
  let cyab : FixedArray[Double] = FixedArray::make(8, 0.0)
  let cyab_length = scale_expansion_zeroelim(ab, 4, cdy, cyab)
  let cyyab : FixedArray[Double] = FixedArray::make(16, 0.0)
  let cyyab_length = scale_expansion_zeroelim(cyab, cyab_length, cdy, cyyab)
  let cdet : FixedArray[Double] = FixedArray::make(32, 0.0)
  let clen = fast_expansion_sum_zeroelim(
    cxxab, cxxab_length, cyyab, cyyab_length, cdet,
  )
  let abdet : FixedArray[Double] = FixedArray::make(64, 0.0)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let fin1 : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let mut finlen = fast_expansion_sum_zeroelim(abdet, ablen, cdet, clen, fin1)
  let mut det = estimate(fin1, finlen)
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
  det = det +
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
  let fin2 : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let temp16a : FixedArray[Double] = FixedArray::make(16, 0.0)
  let temp16b : FixedArray[Double] = FixedArray::make(16, 0.0)
  let temp16c : FixedArray[Double] = FixedArray::make(16, 0.0)
  let temp32a : FixedArray[Double] = FixedArray::make(32, 0.0)
  let temp48 : FixedArray[Double] = FixedArray::make(48, 0.0)
  let aa : FixedArray[Double] = FixedArray::make(4, 0.0)
  let bb : FixedArray[Double] = FixedArray::make(4, 0.0)
  let cc : FixedArray[Double] = FixedArray::make(4, 0.0)
  if bdxtail != 0.0 || bdytail != 0.0 || cdxtail != 0.0 || cdytail != 0.0 {
    let (adxadx1, adxadx0) = square(adx)
    let (adyady1, adyady0) = square(ady)
    let (aa3, aa2, aa1, aa0) = two_two_sum(adxadx1, adxadx0, adyady1, adyady0)
    aa[0] = aa0
    aa[1] = aa1
    aa[2] = aa2
    aa[3] = aa3
  }
  if cdxtail != 0.0 || cdytail != 0.0 || adxtail != 0.0 || adytail != 0.0 {
    let (bdxbdx1, bdxbdx0) = square(bdx)
    let (bdybdy1, bdybdy0) = square(bdy)
    let (bb3, bb2, bb1, bb0) = two_two_sum(bdxbdx1, bdxbdx0, bdybdy1, bdybdy0)
    bb[0] = bb0
    bb[1] = bb1
    bb[2] = bb2
    bb[3] = bb3
  }
  if adxtail != 0.0 || adytail != 0.0 || bdxtail != 0.0 || bdytail != 0.0 {
    let (cdxcdx1, cdxcdx0) = square(cdx)
    let (cdycdy1, cdycdy0) = square(cdy)
    let (cc3, cc2, cc1, cc0) = two_two_sum(cdxcdx1, cdxcdx0, cdycdy1, cdycdy0)
    cc[0] = cc0
    cc[1] = cc1
    cc[2] = cc2
    cc[3] = cc3
  }
  let axtbc : FixedArray[Double] = FixedArray::make(8, 0.0)
  let mut axtbc_length = 0
  if adxtail != 0.0 {
    axtbc_length = scale_expansion_zeroelim(bc, 4, adxtail, axtbc)
    let temp16alen = scale_expansion_zeroelim(
      axtbc,
      axtbc_length,
      2.0 * adx,
      temp16a,
    )
    let axtcc : FixedArray[Double] = FixedArray::make(8, 0.0)
    let axtcc_length = scale_expansion_zeroelim(cc, 4, adxtail, axtcc)
    let temp16blen = scale_expansion_zeroelim(axtcc, axtcc_length, bdy, temp16b)
    let axtbb : FixedArray[Double] = FixedArray::make(8, 0.0)
    let axtbb_length = scale_expansion_zeroelim(bb, 4, adxtail, axtbb)
    let temp16clen = scale_expansion_zeroelim(
      axtbb,
      axtbb_length,
      -cdy,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  if adytail != 0.0 {
    let aytbc : FixedArray[Double] = FixedArray::make(8, 0.0)
    let aytbc_length = scale_expansion_zeroelim(bc, 4, adytail, aytbc)
    let temp16alen = scale_expansion_zeroelim(
      aytbc,
      aytbc_length,
      2.0 * ady,
      temp16a,
    )
    let aytbb : FixedArray[Double] = FixedArray::make(8, 0.0)
    let aytbb_length = scale_expansion_zeroelim(bb, 4, adytail, aytbb)
    let temp16blen = scale_expansion_zeroelim(aytbb, aytbb_length, cdx, temp16b)
    let aytcc : FixedArray[Double] = FixedArray::make(8, 0.0)
    let aytcc_length = scale_expansion_zeroelim(cc, 4, adytail, aytcc)
    let temp16clen = scale_expansion_zeroelim(
      aytcc,
      aytcc_length,
      -bdx,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  if bdxtail != 0.0 {
    let bxtca : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bxtca_length = scale_expansion_zeroelim(ca, 4, bdxtail, bxtca)
    let temp16alen = scale_expansion_zeroelim(
      bxtca,
      bxtca_length,
      2.0 * bdx,
      temp16a,
    )
    let bxtaa : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bxtaa_length = scale_expansion_zeroelim(aa, 4, bdxtail, bxtaa)
    let temp16blen = scale_expansion_zeroelim(bxtaa, bxtaa_length, cdy, temp16b)
    let bxtcc : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bxtcc_length = scale_expansion_zeroelim(cc, 4, bdxtail, bxtcc)
    let temp16clen = scale_expansion_zeroelim(
      bxtcc,
      bxtcc_length,
      -ady,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  if bdytail != 0.0 {
    let bytca : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bytca_length = scale_expansion_zeroelim(ca, 4, bdytail, bytca)
    let temp16alen = scale_expansion_zeroelim(
      bytca,
      bytca_length,
      2.0 * bdy,
      temp16a,
    )
    let bytcc : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bytcc_length = scale_expansion_zeroelim(cc, 4, bdytail, bytcc)
    let temp16blen = scale_expansion_zeroelim(bytcc, bytcc_length, adx, temp16b)
    let bytaa : FixedArray[Double] = FixedArray::make(8, 0.0)
    let bytaa_length = scale_expansion_zeroelim(aa, 4, bdytail, bytaa)
    let temp16clen = scale_expansion_zeroelim(
      bytaa,
      bytaa_length,
      -cdx,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  if cdxtail != 0.0 {
    let cxtab : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cxtab_length = scale_expansion_zeroelim(ab, 4, cdxtail, cxtab)
    let temp16alen = scale_expansion_zeroelim(
      cxtab,
      cxtab_length,
      2.0 * cdx,
      temp16a,
    )
    let cxtbb : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cxtbb_length = scale_expansion_zeroelim(bb, 4, cdxtail, cxtbb)
    let temp16blen = scale_expansion_zeroelim(cxtbb, cxtbb_length, ady, temp16b)
    let cxtaa : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cxtaa_length = scale_expansion_zeroelim(aa, 4, cdxtail, cxtaa)
    let temp16clen = scale_expansion_zeroelim(
      cxtaa,
      cxtaa_length,
      -bdy,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  if cdytail != 0.0 {
    let cytab : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cytab_length = scale_expansion_zeroelim(ab, 4, cdytail, cytab)
    let temp16alen = scale_expansion_zeroelim(
      cytab,
      cytab_length,
      2.0 * cdy,
      temp16a,
    )
    let cytaa : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cytaa_length = scale_expansion_zeroelim(aa, 4, cdytail, cytaa)
    let temp16blen = scale_expansion_zeroelim(cytaa, cytaa_length, bdx, temp16b)
    let cytbb : FixedArray[Double] = FixedArray::make(8, 0.0)
    let cytbb_length = scale_expansion_zeroelim(bb, 4, cdytail, cytbb)
    let temp16clen = scale_expansion_zeroelim(
      cytbb,
      cytbb_length,
      -adx,
      temp16c,
    )
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlen = fast_expansion_sum_zeroelim(fin1, finlen, temp48, temp48len, fin2)
    for i = 0; i < finlen; i = i + 1 {
      fin1[i] = fin2[i]
    }
  }
  fin1[finlen - 1]
}

///|
/// 2D内接円テスト
///
/// 3点(pa, pb, pc)が反時計回りに並んでいるとき、点pdがその外接円の内部にあるか判定する。
/// - 正の値: pdが円の内部にある
/// - 負の値: pdが円の外部にある
/// - 0: pdが円周上にある
pub fn incircle(
  pa : @geojson.Position,
  pb : @geojson.Position,
  pc : @geojson.Position,
  pd : @geojson.Position,
) -> Double {
  let pa = to_coord(pa)
  let pb = to_coord(pb)
  let pc = to_coord(pc)
  let pd = to_coord(pd)
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
    incircleadapt(pa, pb, pc, pd, permanent)
  }
}

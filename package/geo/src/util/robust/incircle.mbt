///|
/// Returns a positive value if the coordinate `pd` lies **inside** the circle passing through `pa`, `pb`, and `pc`.
/// Returns a negative value if it lies **outside** the circle.
/// Returns `0` if the four points are **cocircular**.
/// **Note**: The points `pa`, `pb`, and `pc` must be in **counterclockwise order**, or the sign of the result will be reversed.
pub fn[C : @type.Coord2DTrait] incircle(
  pa : C,
  pb : C,
  pc : C,
  pd : C,
) -> Double {
  let pa_x = pa.x()
  let pa_y = pa.y()
  let pb_x = pb.x()
  let pb_y = pb.y()
  let pc_x = pc.x()
  let pc_y = pc.y()
  let pd_x = pd.x()
  let pd_y = pd.y()
  let adx = pa_x - pd_x
  let bdx = pb_x - pd_x
  let cdx = pc_x - pd_x
  let ady = pa_y - pd_y
  let bdy = pb_y - pd_y
  let cdy = pc_y - pd_y
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
  let permanent = (bdxcdy.abs() + cdxbdy.abs()) * alift +
    (cdxady.abs() + adxcdy.abs()) * blift +
    (adxbdy.abs() + bdxady.abs()) * clift
  let errbound = ICCERRBOUND_A * permanent
  if det > errbound || -det > errbound {
    return det
  }
  incircleadapt(pa_x, pa_y, pb_x, pb_y, pc_x, pc_y, pd_x, pd_y, permanent)
}

///|
fn incircleadapt(
  pa_x : Double,
  pa_y : Double,
  pb_x : Double,
  pb_y : Double,
  pc_x : Double,
  pc_y : Double,
  pd_x : Double,
  pd_y : Double,
  permanent : Double,
) -> Double {
  let temp16a = Array::make(16, 0.0)
  let temp16b = Array::make(16, 0.0)
  let temp16c = Array::make(16, 0.0)
  let temp32a = Array::make(32, 0.0)
  let temp32b = Array::make(32, 0.0)
  let temp48 = Array::make(48, 0.0)
  let temp64 = Array::make(64, 0.0)
  let adx = pa_x - pd_x
  let bdx = pb_x - pd_x
  let cdx = pc_x - pd_x
  let ady = pa_y - pd_y
  let bdy = pb_y - pd_y
  let cdy = pc_y - pd_y
  let (bdxcdy1, bdxcdy0) = two_product(bdx, cdy)
  let (cdxbdy1, cdxbdy0) = two_product(cdx, bdy)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
  let bc = [bc0, bc1, bc2, bc3]
  let axbc = Array::make(8, 0.0)
  let axbclen = scale_expansion_zeroelim(bc, 4, adx, axbc)
  let axxbc = Array::make(16, 0.0)
  let axxbclen = scale_expansion_zeroelim(axbc, axbclen, adx, axxbc)
  let aybc = Array::make(8, 0.0)
  let aybclen = scale_expansion_zeroelim(bc, 4, ady, aybc)
  let ayybc = Array::make(16, 0.0)
  let ayybclen = scale_expansion_zeroelim(aybc, aybclen, ady, ayybc)
  let adet = Array::make(32, 0.0)
  let alen = fast_expansion_sum_zeroelim(axxbc, axxbclen, ayybc, ayybclen, adet)
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca = [ca0, ca1, ca2, ca3]
  let bxca = Array::make(8, 0.0)
  let bxcalen = scale_expansion_zeroelim(ca, 4, bdx, bxca)
  let bxxca = Array::make(16, 0.0)
  let bxxcalen = scale_expansion_zeroelim(bxca, bxcalen, bdx, bxxca)
  let byca = Array::make(8, 0.0)
  let bycalen = scale_expansion_zeroelim(ca, 4, bdy, byca)
  let byyca = Array::make(16, 0.0)
  let byycalen = scale_expansion_zeroelim(byca, bycalen, bdy, byyca)
  let bdet = Array::make(32, 0.0)
  let blen = fast_expansion_sum_zeroelim(bxxca, bxxcalen, byyca, byycalen, bdet)
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab = [ab0, ab1, ab2, ab3]
  let cxab = Array::make(8, 0.0)
  let cxablen = scale_expansion_zeroelim(ab, 4, cdx, cxab)
  let cxxab = Array::make(16, 0.0)
  let cxxablen = scale_expansion_zeroelim(cxab, cxablen, cdx, cxxab)
  let cyab = Array::make(8, 0.0)
  let cyablen = scale_expansion_zeroelim(ab, 4, cdy, cyab)
  let cyyab = Array::make(16, 0.0)
  let cyyablen = scale_expansion_zeroelim(cyab, cyablen, cdy, cyyab)
  let cdet = Array::make(32, 0.0)
  let clen = fast_expansion_sum_zeroelim(cxxab, cxxablen, cyyab, cyyablen, cdet)
  let abdet = Array::make(64, 0.0)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let fin1 = Array::make(1152, 0.0)
  let mut finlength = fast_expansion_sum_zeroelim(
    abdet, ablen, cdet, clen, fin1,
  )
  let mut det = estimate(fin1, finlength)
  let errbound = ICCERRBOUND_B * permanent
  if det >= errbound || -det >= errbound {
    return det
  }
  let adxtail = two_diff_tail(pa_x, pd_x, adx)
  let adytail = two_diff_tail(pa_y, pd_y, ady)
  let bdxtail = two_diff_tail(pb_x, pd_x, bdx)
  let bdytail = two_diff_tail(pb_y, pd_y, bdy)
  let cdxtail = two_diff_tail(pc_x, pd_x, cdx)
  let cdytail = two_diff_tail(pc_y, pd_y, cdy)
  if adxtail == 0.0 &&
    bdxtail == 0.0 &&
    cdxtail == 0.0 &&
    adytail == 0.0 &&
    bdytail == 0.0 &&
    cdytail == 0.0 {
    return det
  }
  let errbound = ICCERRBOUND_C * permanent + RESULTERRBOUND * det.abs()
  det += (adx * adx + ady * ady) *
    (bdx * cdytail + cdy * bdxtail - (bdy * cdxtail + cdx * bdytail)) +
    2.0 * (adx * adxtail + ady * adytail) * (bdx * cdy - bdy * cdx) +
    (
      (bdx * bdx + bdy * bdy) *
      (cdx * adytail + ady * cdxtail - (cdy * adxtail + adx * cdytail)) +
      2.0 * (bdx * bdxtail + bdy * bdytail) * (cdx * ady - cdy * adx)
    ) +
    (
      (cdx * cdx + cdy * cdy) *
      (adx * bdytail + bdy * adxtail - (ady * bdxtail + bdx * adytail)) +
      2.0 * (cdx * cdxtail + cdy * cdytail) * (adx * bdy - ady * bdx)
    )
  if det >= errbound || -det >= errbound {
    return det
  }
  let fin2 = Array::make(1152, 0.0)
  let aa = if bdxtail != 0.0 ||
    bdytail != 0.0 ||
    cdxtail != 0.0 ||
    cdytail != 0.0 {
    let (adxadx1, adxadx0) = square(adx)
    let (adyady1, adyady0) = square(ady)
    let (aa3, aa2, aa1, aa0) = two_two_sum(adxadx1, adxadx0, adyady1, adyady0)
    [aa0, aa1, aa2, aa3]
  } else {
    [0.0, 0.0, 0.0, 0.0]
  }
  let bb = if cdxtail != 0.0 ||
    cdytail != 0.0 ||
    adxtail != 0.0 ||
    adytail != 0.0 {
    let (bdxbdx1, bdxbdx0) = square(bdx)
    let (bdybdy1, bdybdy0) = square(bdy)
    let (bb3, bb2, bb1, bb0) = two_two_sum(bdxbdx1, bdxbdx0, bdybdy1, bdybdy0)
    [bb0, bb1, bb2, bb3]
  } else {
    [0.0, 0.0, 0.0, 0.0]
  }
  let cc = if adxtail != 0.0 ||
    adytail != 0.0 ||
    bdxtail != 0.0 ||
    bdytail != 0.0 {
    let (cdxcdx1, cdxcdx0) = square(cdx)
    let (cdycdy1, cdycdy0) = square(cdy)
    let (cc3, cc2, cc1, cc0) = two_two_sum(cdxcdx1, cdxcdx0, cdycdy1, cdycdy0)
    [cc0, cc1, cc2, cc3]
  } else {
    [0.0, 0.0, 0.0, 0.0]
  }
  let mut axtbclen = 9
  let axtbc = Array::make(8, 0.0)
  if adxtail != 0.0 {
    axtbclen = scale_expansion_zeroelim(bc, 4, adxtail, axtbc)
    let temp16alen = scale_expansion_zeroelim(
      axtbc,
      axtbclen,
      2.0 * adx,
      temp16a,
    )
    let axtcc = Array::make(8, 0.0)
    let axtcclen = scale_expansion_zeroelim(cc, 4, adxtail, axtcc)
    let temp16blen = scale_expansion_zeroelim(axtcc, axtcclen, bdy, temp16b)
    let axtbb = Array::make(8, 0.0)
    let axtbblen = scale_expansion_zeroelim(bb, 4, adxtail, axtbb)
    let temp16clen = scale_expansion_zeroelim(axtbb, axtbblen, -cdy, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  let mut aytbclen = 9
  let aytbc = Array::make(8, 0.0)
  if adytail != 0.0 {
    aytbclen = scale_expansion_zeroelim(bc, 4, adytail, aytbc)
    let temp16alen = scale_expansion_zeroelim(
      aytbc,
      aytbclen,
      2.0 * ady,
      temp16a,
    )
    let aytbb = Array::make(8, 0.0)
    let aytbblen = scale_expansion_zeroelim(bb, 4, adytail, aytbb)
    let temp16blen = scale_expansion_zeroelim(aytbb, aytbblen, cdx, temp16b)
    let aytcc = Array::make(8, 0.0)
    let aytcclen = scale_expansion_zeroelim(cc, 4, adytail, aytcc)
    let temp16clen = scale_expansion_zeroelim(aytcc, aytcclen, -bdx, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  let mut bxtcalen = 9
  let bxtca = Array::make(8, 0.0)
  if bdxtail != 0.0 {
    bxtcalen = scale_expansion_zeroelim(ca, 4, bdxtail, bxtca)
    let temp16alen = scale_expansion_zeroelim(
      bxtca,
      bxtcalen,
      2.0 * bdx,
      temp16a,
    )
    let bxtaa = Array::make(8, 0.0)
    let bxtaalen = scale_expansion_zeroelim(aa, 4, bdxtail, bxtaa)
    let temp16blen = scale_expansion_zeroelim(bxtaa, bxtaalen, cdy, temp16b)
    let bxtcc = Array::make(8, 0.0)
    let bxtcclen = scale_expansion_zeroelim(cc, 4, bdxtail, bxtcc)
    let temp16clen = scale_expansion_zeroelim(bxtcc, bxtcclen, -ady, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  let mut bytcalen = 9
  let bytca = Array::make(8, 0.0)
  if bdytail != 0.0 {
    bytcalen = scale_expansion_zeroelim(ca, 4, bdytail, bytca)
    let temp16alen = scale_expansion_zeroelim(
      bytca,
      bytcalen,
      2.0 * bdy,
      temp16a,
    )
    let bytcc = Array::make(8, 0.0)
    let bytcclen = scale_expansion_zeroelim(cc, 4, bdytail, bytcc)
    let temp16blen = scale_expansion_zeroelim(bytcc, bytcclen, adx, temp16b)
    let bytaa = Array::make(8, 0.0)
    let bytaalen = scale_expansion_zeroelim(aa, 4, bdytail, bytaa)
    let temp16clen = scale_expansion_zeroelim(bytaa, bytaalen, -cdx, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  let mut cxtablen = 9
  let cxtab = Array::make(8, 0.0)
  if cdxtail != 0.0 {
    cxtablen = scale_expansion_zeroelim(ab, 4, cdxtail, cxtab)
    let temp16alen = scale_expansion_zeroelim(
      cxtab,
      cxtablen,
      2.0 * cdx,
      temp16a,
    )
    let cxtbb = Array::make(8, 0.0)
    let cxtbblen = scale_expansion_zeroelim(bb, 4, cdxtail, cxtbb)
    let temp16blen = scale_expansion_zeroelim(cxtbb, cxtbblen, ady, temp16b)
    let cxtaa = Array::make(8, 0.0)
    let cxtaalen = scale_expansion_zeroelim(aa, 4, cdxtail, cxtaa)
    let temp16clen = scale_expansion_zeroelim(cxtaa, cxtaalen, -bdy, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  let mut cytablen = 9
  let cytab = Array::make(8, 0.0)
  if cdytail != 0.0 {
    cytablen = scale_expansion_zeroelim(ab, 4, cdytail, cytab)
    let temp16alen = scale_expansion_zeroelim(
      cytab,
      cytablen,
      2.0 * cdy,
      temp16a,
    )
    let cytaa = Array::make(8, 0.0)
    let cytaalen = scale_expansion_zeroelim(aa, 4, cdytail, cytaa)
    let temp16blen = scale_expansion_zeroelim(cytaa, cytaalen, bdx, temp16b)
    let cytbb = Array::make(8, 0.0)
    let cytbblen = scale_expansion_zeroelim(bb, 4, cdytail, cytbb)
    let temp16clen = scale_expansion_zeroelim(cytbb, cytbblen, -adx, temp16c)
    let temp32alen = fast_expansion_sum_zeroelim(
      temp16a, temp16alen, temp16b, temp16blen, temp32a,
    )
    let temp48len = fast_expansion_sum_zeroelim(
      temp16c, temp16clen, temp32a, temp32alen, temp48,
    )
    finlength = fast_expansion_sum_zeroelim(
      fin1, finlength, temp48, temp48len, fin2,
    )
    simple_swap(fin1, fin2)
  }
  if adxtail != 0.0 || adytail != 0.0 {
    let bctt = [0.0, 0.0, 0.0, 0.0]
    let bct = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let mut bcttlen = 1
    let mut bctlen = 1
    if bdxtail != 0.0 || bdytail != 0.0 || cdxtail != 0.0 || cdytail != 0.0 {
      let (ti1, ti0) = two_product(bdxtail, cdy)
      let (tj1, tj0) = two_product(bdx, cdytail)
      let (u3, u2, u1, u0) = two_two_sum(ti1, ti0, tj1, tj0)
      let u = [u0, u1, u2, u3]
      let negate = -bdy
      let (ti1, ti0) = two_product(cdxtail, negate)
      let negate = -bdytail
      let (tj1, tj0) = two_product(cdx, negate)
      let (v3, v2, v1, v0) = two_two_sum(ti1, ti0, tj1, tj0)
      let v = [v0, v1, v2, v3]
      bctlen = fast_expansion_sum_zeroelim(u, 4, v, 4, bct)
      let (ti1, ti0) = two_product(bdxtail, cdytail)
      let (tj1, tj0) = two_product(cdxtail, bdytail)
      let (bctt3, bctt2, bctt1, bctt0) = two_two_diff(ti1, ti0, tj1, tj0)
      bctt[3] = bctt3
      bctt[2] = bctt2
      bctt[1] = bctt1
      bctt[0] = bctt0
      bcttlen = 4
    } else {
      bct[0] = 0.0
      bctlen = 1
      bctt[0] = 0.0
      bcttlen = 1
    }
    if adxtail != 0.0 {
      let axtbct = Array::make(16, 0.0)
      let axtbctlen = scale_expansion_zeroelim(bct, bctlen, adxtail, axtbct)
      let temp32alen = scale_expansion_zeroelim(
        axtbct,
        axtbctlen,
        2.0 * adx,
        temp32a,
      )
      let axtbctt = Array::make(8, 0.0)
      let axtbcttlen = scale_expansion_zeroelim(bctt, bcttlen, adxtail, axtbctt)
      let temp16alen = scale_expansion_zeroelim(
        axtbctt,
        axtbcttlen,
        2.0 * adx,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        axtbctt, axtbcttlen, adxtail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
    if adytail != 0.0 {
      let aytbct = Array::make(16, 0.0)
      let aytbctlen = scale_expansion_zeroelim(bct, bctlen, adytail, aytbct)
      let temp32alen = scale_expansion_zeroelim(
        aytbct,
        aytbctlen,
        2.0 * ady,
        temp32a,
      )
      let aytbctt = Array::make(8, 0.0)
      let aytbcttlen = scale_expansion_zeroelim(bctt, bcttlen, adytail, aytbctt)
      let temp16alen = scale_expansion_zeroelim(
        aytbctt,
        aytbcttlen,
        2.0 * ady,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        aytbctt, aytbcttlen, adytail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
  }
  if bdxtail != 0.0 || bdytail != 0.0 {
    let catt = [0.0, 0.0, 0.0, 0.0]
    let cat = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let mut cattlen = 1
    let mut catlen = 1
    if cdxtail != 0.0 || cdytail != 0.0 || adxtail != 0.0 || adytail != 0.0 {
      let (ti1, ti0) = two_product(cdxtail, ady)
      let (tj1, tj0) = two_product(cdx, adytail)
      let (u3, u2, u1, u0) = two_two_sum(ti1, ti0, tj1, tj0)
      let u = [u0, u1, u2, u3]
      let negate = -cdy
      let (ti1, ti0) = two_product(adxtail, negate)
      let negate = -cdytail
      let (tj1, tj0) = two_product(adx, negate)
      let (v3, v2, v1, v0) = two_two_sum(ti1, ti0, tj1, tj0)
      let v = [v0, v1, v2, v3]
      catlen = fast_expansion_sum_zeroelim(u, 4, v, 4, cat)
      let (ti1, ti0) = two_product(cdxtail, adytail)
      let (tj1, tj0) = two_product(adxtail, cdytail)
      let (catt3, catt2, catt1, catt0) = two_two_diff(ti1, ti0, tj1, tj0)
      catt[3] = catt3
      catt[2] = catt2
      catt[1] = catt1
      catt[0] = catt0
      cattlen = 4
    } else {
      cat[0] = 0.0
      catlen = 1
      catt[0] = 0.0
      cattlen = 1
    }
    if bdxtail != 0.0 {
      let bxtcat = Array::make(16, 0.0)
      let bxtcatlen = scale_expansion_zeroelim(cat, catlen, bdxtail, bxtcat)
      let temp32alen = scale_expansion_zeroelim(
        bxtcat,
        bxtcatlen,
        2.0 * bdx,
        temp32a,
      )
      let bxtcatt = Array::make(8, 0.0)
      let bxtcattlen = scale_expansion_zeroelim(catt, cattlen, bdxtail, bxtcatt)
      let temp16alen = scale_expansion_zeroelim(
        bxtcatt,
        bxtcattlen,
        2.0 * bdx,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        bxtcatt, bxtcattlen, bdxtail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
    if bdytail != 0.0 {
      let bytcat = Array::make(16, 0.0)
      let bytcatlen = scale_expansion_zeroelim(cat, catlen, bdytail, bytcat)
      let temp32alen = scale_expansion_zeroelim(
        bytcat,
        bytcatlen,
        2.0 * bdy,
        temp32a,
      )
      let bytcatt = Array::make(8, 0.0)
      let bytcattlen = scale_expansion_zeroelim(catt, cattlen, bdytail, bytcatt)
      let temp16alen = scale_expansion_zeroelim(
        bytcatt,
        bytcattlen,
        2.0 * bdy,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        bytcatt, bytcattlen, bdytail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
  }
  if cdxtail != 0.0 || cdytail != 0.0 {
    let abtt = [0.0, 0.0, 0.0, 0.0]
    let abt = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let mut abttlen = 1
    let mut abtlen = 1
    if adxtail != 0.0 || adytail != 0.0 || bdxtail != 0.0 || bdytail != 0.0 {
      let (ti1, ti0) = two_product(adxtail, bdy)
      let (tj1, tj0) = two_product(adx, bdytail)
      let (u3, u2, u1, u0) = two_two_sum(ti1, ti0, tj1, tj0)
      let u = [u0, u1, u2, u3]
      let negate = -ady
      let (ti1, ti0) = two_product(bdxtail, negate)
      let negate = -adytail
      let (tj1, tj0) = two_product(bdx, negate)
      let (v3, v2, v1, v0) = two_two_sum(ti1, ti0, tj1, tj0)
      let v = [v0, v1, v2, v3]
      abtlen = fast_expansion_sum_zeroelim(u, 4, v, 4, abt)
      let (ti1, ti0) = two_product(adxtail, bdytail)
      let (tj1, tj0) = two_product(bdxtail, adytail)
      let (abtt3, abtt2, abtt1, abtt0) = two_two_diff(ti1, ti0, tj1, tj0)
      abtt[3] = abtt3
      abtt[2] = abtt2
      abtt[1] = abtt1
      abtt[0] = abtt0
      abttlen = 4
    } else {
      abt[0] = 0.0
      abtlen = 1
      abtt[0] = 0.0
      abttlen = 1
    }
    if cdxtail != 0.0 {
      let cxtabt = Array::make(16, 0.0)
      let cxtabtlen = scale_expansion_zeroelim(abt, abtlen, cdxtail, cxtabt)
      let temp32alen = scale_expansion_zeroelim(
        cxtabt,
        cxtabtlen,
        2.0 * cdx,
        temp32a,
      )
      let cxtabtt = Array::make(8, 0.0)
      let cxtabttlen = scale_expansion_zeroelim(abtt, abttlen, cdxtail, cxtabtt)
      let temp16alen = scale_expansion_zeroelim(
        cxtabtt,
        cxtabttlen,
        2.0 * cdx,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        cxtabtt, cxtabttlen, cdxtail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
    if cdytail != 0.0 {
      let cytabt = Array::make(16, 0.0)
      let cytabtlen = scale_expansion_zeroelim(abt, abtlen, cdytail, cytabt)
      let temp32alen = scale_expansion_zeroelim(
        cytabt,
        cytabtlen,
        2.0 * cdy,
        temp32a,
      )
      let cytabtt = Array::make(8, 0.0)
      let cytabttlen = scale_expansion_zeroelim(abtt, abttlen, cdytail, cytabtt)
      let temp16alen = scale_expansion_zeroelim(
        cytabtt,
        cytabttlen,
        2.0 * cdy,
        temp16a,
      )
      let temp16blen = scale_expansion_zeroelim(
        cytabtt, cytabttlen, cdytail, temp16b,
      )
      let temp32blen = fast_expansion_sum_zeroelim(
        temp16a, temp16alen, temp16b, temp16blen, temp32b,
      )
      let temp64len = fast_expansion_sum_zeroelim(
        temp32a, temp32alen, temp32b, temp32blen, temp64,
      )
      finlength = fast_expansion_sum_zeroelim(
        fin1, finlength, temp64, temp64len, fin2,
      )
      simple_swap(fin1, fin2)
    }
  }
  fin1[finlength - 1]
}

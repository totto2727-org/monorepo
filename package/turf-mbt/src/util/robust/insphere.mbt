///|
/// insphere 誤差境界 A
let insphere_err_bound_a : Double = (16.0 + 224.0 * epsilon) * epsilon

///|
/// insphere 誤差境界 B
let insphere_err_bound_b : Double = (5.0 + 72.0 * epsilon) * epsilon

///|
/// insphere 誤差境界 C
let insphere_err_bound_c : Double = (71.0 + 1408.0 * epsilon) *
  epsilon *
  epsilon

///|
/// insphere の完全精度計算（内部関数）
fn insphere_exact(
  pa : Coord3D,
  pb : Coord3D,
  pc : Coord3D,
  pd : Coord3D,
  pe : Coord3D,
) -> Double {
  let (axby1, axby0) = two_product(pa.x, pb.y)
  let (bxay1, bxay0) = two_product(pb.x, pa.y)
  let (ab3, ab2, ab1, ab0) = two_two_diff(axby1, axby0, bxay1, bxay0)
  let ab : FixedArray[Double] = [ab0, ab1, ab2, ab3]
  let (bxcy1, bxcy0) = two_product(pb.x, pc.y)
  let (cxby1, cxby0) = two_product(pc.x, pb.y)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bxcy1, bxcy0, cxby1, cxby0)
  let bc : FixedArray[Double] = [bc0, bc1, bc2, bc3]
  let (cxdy1, cxdy0) = two_product(pc.x, pd.y)
  let (dxcy1, dxcy0) = two_product(pd.x, pc.y)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cxdy1, cxdy0, dxcy1, dxcy0)
  let cd : FixedArray[Double] = [cd0, cd1, cd2, cd3]
  let (dxey1, dxey0) = two_product(pd.x, pe.y)
  let (exdy1, exdy0) = two_product(pe.x, pd.y)
  let (de3, de2, de1, de0) = two_two_diff(dxey1, dxey0, exdy1, exdy0)
  let de : FixedArray[Double] = [de0, de1, de2, de3]
  let (exay1, exay0) = two_product(pe.x, pa.y)
  let (axey1, axey0) = two_product(pa.x, pe.y)
  let (ea3, ea2, ea1, ea0) = two_two_diff(exay1, exay0, axey1, axey0)
  let ea : FixedArray[Double] = [ea0, ea1, ea2, ea3]
  let (axcy1, axcy0) = two_product(pa.x, pc.y)
  let (cxay1, cxay0) = two_product(pc.x, pa.y)
  let (ac3, ac2, ac1, ac0) = two_two_diff(axcy1, axcy0, cxay1, cxay0)
  let ac : FixedArray[Double] = [ac0, ac1, ac2, ac3]
  let (bxdy1, bxdy0) = two_product(pb.x, pd.y)
  let (dxby1, dxby0) = two_product(pd.x, pb.y)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bxdy1, bxdy0, dxby1, dxby0)
  let bd : FixedArray[Double] = [bd0, bd1, bd2, bd3]
  let (cxey1, cxey0) = two_product(pc.x, pe.y)
  let (excy1, excy0) = two_product(pe.x, pc.y)
  let (ce3, ce2, ce1, ce0) = two_two_diff(cxey1, cxey0, excy1, excy0)
  let ce : FixedArray[Double] = [ce0, ce1, ce2, ce3]
  let (dxay1, dxay0) = two_product(pd.x, pa.y)
  let (axdy1, axdy0) = two_product(pa.x, pd.y)
  let (da3, da2, da1, da0) = two_two_diff(dxay1, dxay0, axdy1, axdy0)
  let da : FixedArray[Double] = [da0, da1, da2, da3]
  let (exby1, exby0) = two_product(pe.x, pb.y)
  let (bxey1, bxey0) = two_product(pb.x, pe.y)
  let (eb3, eb2, eb1, eb0) = two_two_diff(exby1, exby0, bxey1, bxey0)
  let eb : FixedArray[Double] = [eb0, eb1, eb2, eb3]
  let temp8a : FixedArray[Double] = FixedArray::make(8, 0.0)
  let temp8b : FixedArray[Double] = FixedArray::make(8, 0.0)
  let temp16 : FixedArray[Double] = FixedArray::make(16, 0.0)
  let abc : FixedArray[Double] = FixedArray::make(24, 0.0)
  let bcd : FixedArray[Double] = FixedArray::make(24, 0.0)
  let cde : FixedArray[Double] = FixedArray::make(24, 0.0)
  let dea : FixedArray[Double] = FixedArray::make(24, 0.0)
  let eab : FixedArray[Double] = FixedArray::make(24, 0.0)
  let abd : FixedArray[Double] = FixedArray::make(24, 0.0)
  let bce : FixedArray[Double] = FixedArray::make(24, 0.0)
  let cda : FixedArray[Double] = FixedArray::make(24, 0.0)
  let deb : FixedArray[Double] = FixedArray::make(24, 0.0)
  let eac : FixedArray[Double] = FixedArray::make(24, 0.0)
  let mut t8alen = scale_expansion_zeroelim(bc, 4, pa.z, temp8a)
  let mut t8blen = scale_expansion_zeroelim(ac, 4, -pb.z, temp8b)
  let mut t16len = fast_expansion_sum_zeroelim(
    temp8a, t8alen, temp8b, t8blen, temp16,
  )
  t8alen = scale_expansion_zeroelim(ab, 4, pc.z, temp8a)
  let abclen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, abc)
  t8alen = scale_expansion_zeroelim(cd, 4, pb.z, temp8a)
  t8blen = scale_expansion_zeroelim(bd, 4, -pc.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(bc, 4, pd.z, temp8a)
  let bcdlen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, bcd)
  t8alen = scale_expansion_zeroelim(de, 4, pc.z, temp8a)
  t8blen = scale_expansion_zeroelim(ce, 4, -pd.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(cd, 4, pe.z, temp8a)
  let cdelen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, cde)
  t8alen = scale_expansion_zeroelim(ea, 4, pd.z, temp8a)
  t8blen = scale_expansion_zeroelim(da, 4, -pe.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(de, 4, pa.z, temp8a)
  let dealen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, dea)
  t8alen = scale_expansion_zeroelim(ab, 4, pe.z, temp8a)
  t8blen = scale_expansion_zeroelim(eb, 4, -pa.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(ea, 4, pb.z, temp8a)
  let eablen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, eab)
  t8alen = scale_expansion_zeroelim(bd, 4, pa.z, temp8a)
  t8blen = scale_expansion_zeroelim(da, 4, pb.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(ab, 4, pd.z, temp8a)
  let abdlen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, abd)
  t8alen = scale_expansion_zeroelim(ce, 4, pb.z, temp8a)
  t8blen = scale_expansion_zeroelim(eb, 4, pc.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(bc, 4, pe.z, temp8a)
  let bcelen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, bce)
  t8alen = scale_expansion_zeroelim(da, 4, pc.z, temp8a)
  t8blen = scale_expansion_zeroelim(ac, 4, pd.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(cd, 4, pa.z, temp8a)
  let cdalen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, cda)
  t8alen = scale_expansion_zeroelim(eb, 4, pd.z, temp8a)
  t8blen = scale_expansion_zeroelim(bd, 4, pe.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(de, 4, pb.z, temp8a)
  let deblen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, deb)
  t8alen = scale_expansion_zeroelim(ac, 4, pe.z, temp8a)
  t8blen = scale_expansion_zeroelim(ce, 4, pa.z, temp8b)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t8alen = scale_expansion_zeroelim(ea, 4, pc.z, temp8a)
  let eaclen = fast_expansion_sum_zeroelim(temp8a, t8alen, temp16, t16len, eac)
  let temp48a : FixedArray[Double] = FixedArray::make(48, 0.0)
  let temp48b : FixedArray[Double] = FixedArray::make(48, 0.0)
  let bcde : FixedArray[Double] = FixedArray::make(96, 0.0)
  let cdea : FixedArray[Double] = FixedArray::make(96, 0.0)
  let deab : FixedArray[Double] = FixedArray::make(96, 0.0)
  let eabc : FixedArray[Double] = FixedArray::make(96, 0.0)
  let abcd : FixedArray[Double] = FixedArray::make(96, 0.0)
  let temp192 : FixedArray[Double] = FixedArray::make(192, 0.0)
  let det384x : FixedArray[Double] = FixedArray::make(384, 0.0)
  let det384y : FixedArray[Double] = FixedArray::make(384, 0.0)
  let det384z : FixedArray[Double] = FixedArray::make(384, 0.0)
  let detxy : FixedArray[Double] = FixedArray::make(768, 0.0)
  let adet : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let bdet : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let cdet : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let ddet : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let edet : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let ab_det : FixedArray[Double] = FixedArray::make(2304, 0.0)
  let cd_det : FixedArray[Double] = FixedArray::make(2304, 0.0)
  let cde_det : FixedArray[Double] = FixedArray::make(3456, 0.0)
  let deter : FixedArray[Double] = FixedArray::make(5760, 0.0)
  let mut t48alen = fast_expansion_sum_zeroelim(
    cde, cdelen, bce, bcelen, temp48a,
  )
  let mut t48blen = fast_expansion_sum_zeroelim(
    deb, deblen, bcd, bcdlen, temp48b,
  )
  for i = 0; i < t48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let bcdelen = fast_expansion_sum_zeroelim(
    temp48a, t48alen, temp48b, t48blen, bcde,
  )
  let mut xlen = scale_expansion_zeroelim(bcde, bcdelen, pa.x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pa.x, det384x)
  let mut ylen = scale_expansion_zeroelim(bcde, bcdelen, pa.y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pa.y, det384y)
  let mut zlen = scale_expansion_zeroelim(bcde, bcdelen, pa.z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pa.z, det384z)
  let mut xylen = fast_expansion_sum_zeroelim(
    det384x, xlen, det384y, ylen, detxy,
  )
  let alen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, adet)
  t48alen = fast_expansion_sum_zeroelim(dea, dealen, cda, cdalen, temp48a)
  t48blen = fast_expansion_sum_zeroelim(eac, eaclen, cde, cdelen, temp48b)
  for i = 0; i < t48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let cdealen = fast_expansion_sum_zeroelim(
    temp48a, t48alen, temp48b, t48blen, cdea,
  )
  xlen = scale_expansion_zeroelim(cdea, cdealen, pb.x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pb.x, det384x)
  ylen = scale_expansion_zeroelim(cdea, cdealen, pb.y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pb.y, det384y)
  zlen = scale_expansion_zeroelim(cdea, cdealen, pb.z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pb.z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let blen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, bdet)
  t48alen = fast_expansion_sum_zeroelim(eab, eablen, deb, deblen, temp48a)
  t48blen = fast_expansion_sum_zeroelim(abd, abdlen, dea, dealen, temp48b)
  for i = 0; i < t48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let deablen = fast_expansion_sum_zeroelim(
    temp48a, t48alen, temp48b, t48blen, deab,
  )
  xlen = scale_expansion_zeroelim(deab, deablen, pc.x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pc.x, det384x)
  ylen = scale_expansion_zeroelim(deab, deablen, pc.y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pc.y, det384y)
  zlen = scale_expansion_zeroelim(deab, deablen, pc.z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pc.z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let clen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, cdet)
  t48alen = fast_expansion_sum_zeroelim(abc, abclen, eac, eaclen, temp48a)
  t48blen = fast_expansion_sum_zeroelim(bce, bcelen, eab, eablen, temp48b)
  for i = 0; i < t48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let eabclen = fast_expansion_sum_zeroelim(
    temp48a, t48alen, temp48b, t48blen, eabc,
  )
  xlen = scale_expansion_zeroelim(eabc, eabclen, pd.x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pd.x, det384x)
  ylen = scale_expansion_zeroelim(eabc, eabclen, pd.y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pd.y, det384y)
  zlen = scale_expansion_zeroelim(eabc, eabclen, pd.z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pd.z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let dlen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, ddet)
  t48alen = fast_expansion_sum_zeroelim(bcd, bcdlen, abd, abdlen, temp48a)
  t48blen = fast_expansion_sum_zeroelim(cda, cdalen, abc, abclen, temp48b)
  for i = 0; i < t48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let abcdlen = fast_expansion_sum_zeroelim(
    temp48a, t48alen, temp48b, t48blen, abcd,
  )
  xlen = scale_expansion_zeroelim(abcd, abcdlen, pe.x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pe.x, det384x)
  ylen = scale_expansion_zeroelim(abcd, abcdlen, pe.y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pe.y, det384y)
  zlen = scale_expansion_zeroelim(abcd, abcdlen, pe.z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pe.z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let elen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, edet)
  let ab_len = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, ab_det)
  let cd_len = fast_expansion_sum_zeroelim(cdet, clen, ddet, dlen, cd_det)
  let cde_len = fast_expansion_sum_zeroelim(cd_det, cd_len, edet, elen, cde_det)
  let detlen = fast_expansion_sum_zeroelim(
    ab_det, ab_len, cde_det, cde_len, deter,
  )
  deter[detlen - 1]
}

///|
fn insphere_adapt(
  pa : Coord3D,
  pb : Coord3D,
  pc : Coord3D,
  pd : Coord3D,
  pe : Coord3D,
  permanent : Double,
) -> Double {
  // 座標の差分計算
  let aex = pa.x - pe.x
  let bex = pb.x - pe.x
  let cex = pc.x - pe.x
  let dex = pd.x - pe.x
  let aey = pa.y - pe.y
  let bey = pb.y - pe.y
  let cey = pc.y - pe.y
  let dey = pd.y - pe.y
  let aez = pa.z - pe.z
  let bez = pb.z - pe.z
  let cez = pc.z - pe.z
  let dez = pd.z - pe.z
  let (aexbey1, aexbey0) = two_product(aex, bey)
  let (bexaey1, bexaey0) = two_product(bex, aey)
  let (ab3, ab2, ab1, ab0) = two_two_diff(aexbey1, aexbey0, bexaey1, bexaey0)
  let ab : FixedArray[Double] = [ab0, ab1, ab2, ab3]
  let (bexcey1, bexcey0) = two_product(bex, cey)
  let (cexbey1, cexbey0) = two_product(cex, bey)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bexcey1, bexcey0, cexbey1, cexbey0)
  let bc : FixedArray[Double] = [bc0, bc1, bc2, bc3]
  let (cexdey1, cexdey0) = two_product(cex, dey)
  let (dexcey1, dexcey0) = two_product(dex, cey)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cexdey1, cexdey0, dexcey1, dexcey0)
  let cd : FixedArray[Double] = [cd0, cd1, cd2, cd3]
  let (dexaey1, dexaey0) = two_product(dex, aey)
  let (aexdey1, aexdey0) = two_product(aex, dey)
  let (da3, da2, da1, da0) = two_two_diff(dexaey1, dexaey0, aexdey1, aexdey0)
  let da : FixedArray[Double] = [da0, da1, da2, da3]
  let (aexcey1, aexcey0) = two_product(aex, cey)
  let (cexaey1, cexaey0) = two_product(cex, aey)
  let (ac3, ac2, ac1, ac0) = two_two_diff(aexcey1, aexcey0, cexaey1, cexaey0)
  let ac : FixedArray[Double] = [ac0, ac1, ac2, ac3]
  let (bexdey1, bexdey0) = two_product(bex, dey)
  let (dexbey1, dexbey0) = two_product(dex, bey)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bexdey1, bexdey0, dexbey1, dexbey0)
  let bd : FixedArray[Double] = [bd0, bd1, bd2, bd3]
  let temp8a : FixedArray[Double] = FixedArray::make(8, 0.0)
  let temp8b : FixedArray[Double] = FixedArray::make(8, 0.0)
  let temp8c : FixedArray[Double] = FixedArray::make(8, 0.0)
  let temp16 : FixedArray[Double] = FixedArray::make(16, 0.0)
  let temp24 : FixedArray[Double] = FixedArray::make(24, 0.0)
  let temp48 : FixedArray[Double] = FixedArray::make(48, 0.0)
  let xdet : FixedArray[Double] = FixedArray::make(96, 0.0)
  let ydet : FixedArray[Double] = FixedArray::make(96, 0.0)
  let zdet : FixedArray[Double] = FixedArray::make(96, 0.0)
  let xydet : FixedArray[Double] = FixedArray::make(192, 0.0)
  let adet : FixedArray[Double] = FixedArray::make(288, 0.0)
  let bdet : FixedArray[Double] = FixedArray::make(288, 0.0)
  let cdet : FixedArray[Double] = FixedArray::make(288, 0.0)
  let ddet : FixedArray[Double] = FixedArray::make(288, 0.0)
  let abdet : FixedArray[Double] = FixedArray::make(576, 0.0)
  let cddet : FixedArray[Double] = FixedArray::make(576, 0.0)
  let fin1 : FixedArray[Double] = FixedArray::make(1152, 0.0)
  let mut t8alen = scale_expansion_zeroelim(cd, 4, bez, temp8a)
  let mut t8blen = scale_expansion_zeroelim(bd, 4, -cez, temp8b)
  let mut t8clen = scale_expansion_zeroelim(bc, 4, dez, temp8c)
  let mut t16len = fast_expansion_sum_zeroelim(
    temp8a, t8alen, temp8b, t8blen, temp16,
  )
  let mut t24len = fast_expansion_sum_zeroelim(
    temp8c, t8clen, temp16, t16len, temp24,
  )
  let mut t48len = scale_expansion_zeroelim(temp24, t24len, aex, temp48)
  let mut xlen = scale_expansion_zeroelim(temp48, t48len, -aex, xdet)
  t48len = scale_expansion_zeroelim(temp24, t24len, aey, temp48)
  let mut ylen = scale_expansion_zeroelim(temp48, t48len, -aey, ydet)
  t48len = scale_expansion_zeroelim(temp24, t24len, aez, temp48)
  let mut zlen = scale_expansion_zeroelim(temp48, t48len, -aez, zdet)
  let mut xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let alen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, adet)
  t8alen = scale_expansion_zeroelim(da, 4, cez, temp8a)
  t8blen = scale_expansion_zeroelim(ac, 4, dez, temp8b)
  t8clen = scale_expansion_zeroelim(cd, 4, aez, temp8c)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t24len = fast_expansion_sum_zeroelim(temp8c, t8clen, temp16, t16len, temp24)
  t48len = scale_expansion_zeroelim(temp24, t24len, bex, temp48)
  xlen = scale_expansion_zeroelim(temp48, t48len, bex, xdet)
  t48len = scale_expansion_zeroelim(temp24, t24len, bey, temp48)
  ylen = scale_expansion_zeroelim(temp48, t48len, bey, ydet)
  t48len = scale_expansion_zeroelim(temp24, t24len, bez, temp48)
  zlen = scale_expansion_zeroelim(temp48, t48len, bez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let blen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, bdet)
  t8alen = scale_expansion_zeroelim(ab, 4, dez, temp8a)
  t8blen = scale_expansion_zeroelim(bd, 4, aez, temp8b)
  t8clen = scale_expansion_zeroelim(da, 4, bez, temp8c)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t24len = fast_expansion_sum_zeroelim(temp8c, t8clen, temp16, t16len, temp24)
  t48len = scale_expansion_zeroelim(temp24, t24len, cex, temp48)
  xlen = scale_expansion_zeroelim(temp48, t48len, -cex, xdet)
  t48len = scale_expansion_zeroelim(temp24, t24len, cey, temp48)
  ylen = scale_expansion_zeroelim(temp48, t48len, -cey, ydet)
  t48len = scale_expansion_zeroelim(temp24, t24len, cez, temp48)
  zlen = scale_expansion_zeroelim(temp48, t48len, -cez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let clen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, cdet)
  t8alen = scale_expansion_zeroelim(bc, 4, aez, temp8a)
  t8blen = scale_expansion_zeroelim(ac, 4, -bez, temp8b)
  t8clen = scale_expansion_zeroelim(ab, 4, cez, temp8c)
  t16len = fast_expansion_sum_zeroelim(temp8a, t8alen, temp8b, t8blen, temp16)
  t24len = fast_expansion_sum_zeroelim(temp8c, t8clen, temp16, t16len, temp24)
  t48len = scale_expansion_zeroelim(temp24, t24len, dex, temp48)
  xlen = scale_expansion_zeroelim(temp48, t48len, dex, xdet)
  t48len = scale_expansion_zeroelim(temp24, t24len, dey, temp48)
  ylen = scale_expansion_zeroelim(temp48, t48len, dey, ydet)
  t48len = scale_expansion_zeroelim(temp24, t24len, dez, temp48)
  zlen = scale_expansion_zeroelim(temp48, t48len, dez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let dlen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, ddet)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let cdlen = fast_expansion_sum_zeroelim(cdet, clen, ddet, dlen, cddet)
  let finlen = fast_expansion_sum_zeroelim(abdet, ablen, cddet, cdlen, fin1)
  let det = estimate(fin1, finlen)
  let mut errbound = insphere_err_bound_b * permanent
  if det >= errbound || -det >= errbound {
    return det
  }
  let aextail = two_diff_tail(pa.x, pe.x, aex)
  let aeytail = two_diff_tail(pa.y, pe.y, aey)
  let aeztail = two_diff_tail(pa.z, pe.z, aez)
  let bextail = two_diff_tail(pb.x, pe.x, bex)
  let beytail = two_diff_tail(pb.y, pe.y, bey)
  let beztail = two_diff_tail(pb.z, pe.z, bez)
  let cextail = two_diff_tail(pc.x, pe.x, cex)
  let ceytail = two_diff_tail(pc.y, pe.y, cey)
  let ceztail = two_diff_tail(pc.z, pe.z, cez)
  let dextail = two_diff_tail(pd.x, pe.x, dex)
  let deytail = two_diff_tail(pd.y, pe.y, dey)
  let deztail = two_diff_tail(pd.z, pe.z, dez)
  if aextail == 0.0 &&
    aeytail == 0.0 &&
    aeztail == 0.0 &&
    bextail == 0.0 &&
    beytail == 0.0 &&
    beztail == 0.0 &&
    cextail == 0.0 &&
    ceytail == 0.0 &&
    ceztail == 0.0 &&
    dextail == 0.0 &&
    deytail == 0.0 &&
    deztail == 0.0 {
    return det
  }
  errbound = insphere_err_bound_c * permanent + result_err_bound * abs(det)
  let ab_err = aex * beytail + bey * aextail - (aey * bextail + bex * aeytail)
  let bc_err = bex * ceytail + cey * bextail - (bey * cextail + cex * beytail)
  let cd_err = cex * deytail + dey * cextail - (cey * dextail + dex * ceytail)
  let da_err = dex * aeytail + aey * dextail - (dey * aextail + aex * deytail)
  let ac_err = aex * ceytail + cey * aextail - (aey * cextail + cex * aeytail)
  let bd_err = bex * deytail + dey * bextail - (bey * dextail + dex * beytail)
  let det = det +
    (
      (bex * bex + bey * bey + bez * bez) *
      (
        cez * da_err +
        dez * ac_err +
        aez * cd_err +
        (ceztail * da[3] + deztail * ac[3] + aeztail * cd[3])
      ) +
      (dex * dex + dey * dey + dez * dez) *
      (
        aez * bc_err -
        bez * ac_err +
        cez * ab_err +
        (aeztail * bc[3] - beztail * ac[3] + ceztail * ab[3])
      ) -
      (
        (aex * aex + aey * aey + aez * aez) *
        (
          bez * cd_err -
          cez * bd_err +
          dez * bc_err +
          (beztail * cd[3] - ceztail * bd[3] + deztail * bc[3])
        ) +
        (cex * cex + cey * cey + cez * cez) *
        (
          dez * ab_err +
          aez * bd_err +
          bez * da_err +
          (deztail * ab[3] + aeztail * bd[3] + beztail * da[3])
        )
      )
    ) +
    2.0 *
    (
      (bex * bextail + bey * beytail + bez * beztail) *
      (cez * da[3] + dez * ac[3] + aez * cd[3]) +
      (dex * dextail + dey * deytail + dez * deztail) *
      (aez * bc[3] - bez * ac[3] + cez * ab[3]) -
      (
        (aex * aextail + aey * aeytail + aez * aeztail) *
        (bez * cd[3] - cez * bd[3] + dez * bc[3]) +
        (cex * cextail + cey * ceytail + cez * ceztail) *
        (dez * ab[3] + aez * bd[3] + bez * da[3])
      )
    )
  if det >= errbound || -det >= errbound {
    return det
  }
  insphere_exact(pa, pb, pc, pd, pe)
}

///|
/// 3D内接球面テスト
///
/// 4点(pa, pb, pc, pd)が反時計回りに並んでいるとき、点peがその外接球の内部にあるか判定する。
/// - 正の値: peが球の内部にある
/// - 負の値: peが球の外部にある
/// - 0: peが球面上にある
pub fn insphere(
  pa : @geojson.Position,
  pb : @geojson.Position,
  pc : @geojson.Position,
  pd : @geojson.Position,
  pe : @geojson.Position,
) -> Double raise {
  let pa = to_coord3d(pa)
  let pb = to_coord3d(pb)
  let pc = to_coord3d(pc)
  let pd = to_coord3d(pd)
  let pe = to_coord3d(pe)
  let aex = pa.x - pe.x
  let bex = pb.x - pe.x
  let cex = pc.x - pe.x
  let dex = pd.x - pe.x
  let aey = pa.y - pe.y
  let bey = pb.y - pe.y
  let cey = pc.y - pe.y
  let dey = pd.y - pe.y
  let aez = pa.z - pe.z
  let bez = pb.z - pe.z
  let cez = pc.z - pe.z
  let dez = pd.z - pe.z
  let aexbey = aex * bey
  let bexaey = bex * aey
  let ab = aexbey - bexaey
  let bexcey = bex * cey
  let cexbey = cex * bey
  let bc = bexcey - cexbey
  let cexdey = cex * dey
  let dexcey = dex * cey
  let cd = cexdey - dexcey
  let dexaey = dex * aey
  let aexdey = aex * dey
  let da = dexaey - aexdey
  let aexcey = aex * cey
  let cexaey = cex * aey
  let ac = aexcey - cexaey
  let bexdey = bex * dey
  let dexbey = dex * bey
  let bd = bexdey - dexbey
  let abc = aez * bc - bez * ac + cez * ab
  let bcd = bez * cd - cez * bd + dez * bc
  let cda = cez * da + dez * ac + aez * cd
  let dab = dez * ab + aez * bd + bez * da
  let alift = aex * aex + aey * aey + aez * aez
  let blift = bex * bex + bey * bey + bez * bez
  let clift = cex * cex + cey * cey + cez * cez
  let dlift = dex * dex + dey * dey + dez * dez
  let det = dlift * abc - clift * dab + blift * cda - alift * bcd
  let aezplus = abs(aez)
  let bezplus = abs(bez)
  let cezplus = abs(cez)
  let dezplus = abs(dez)
  let aexbeyplus = abs(aexbey)
  let bexaeyplus = abs(bexaey)
  let bexceyplus = abs(bexcey)
  let cexbeyplus = abs(cexbey)
  let cexdeyplus = abs(cexdey)
  let dexceyplus = abs(dexcey)
  let dexaeyplus = abs(dexaey)
  let aexdeyplus = abs(aexdey)
  let aexceyplus = abs(aexcey)
  let cexaeyplus = abs(cexaey)
  let bexdeyplus = abs(bexdey)
  let dexbeyplus = abs(dexbey)
  let permanent = (
      (cexdeyplus + dexceyplus) * bezplus +
      (dexbeyplus + bexdeyplus) * cezplus +
      (bexceyplus + cexbeyplus) * dezplus
    ) *
    alift +
    (
      (dexaeyplus + aexdeyplus) * cezplus +
      (aexceyplus + cexaeyplus) * dezplus +
      (cexdeyplus + dexceyplus) * aezplus
    ) *
    blift +
    (
      (aexbeyplus + bexaeyplus) * dezplus +
      (bexdeyplus + dexbeyplus) * aezplus +
      (dexaeyplus + aexdeyplus) * bezplus
    ) *
    clift +
    (
      (bexceyplus + cexbeyplus) * aezplus +
      (cexaeyplus + aexceyplus) * bezplus +
      (aexbeyplus + bexaeyplus) * cezplus
    ) *
    dlift
  let errbound = insphere_err_bound_a * permanent
  if det > errbound || -det > errbound {
    det
  } else {
    insphere_adapt(pa, pb, pc, pd, pe, permanent)
  }
}

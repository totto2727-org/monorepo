///|
/// Returns a positive value if the point `pe` lies inside the sphere passing through `pa`, `pb`, `pc`, and `pd`.
/// Returns a negative value if it lies outside.
/// Returns `0` if the five points are **cospherical**.
/// **NOTE**: The points `pa`, `pb`, `pc`, and `pd` must be ordered so that they have a positive orientation.
pub fn[C : @type.Coord3DTrait] insphere(
  pa : C,
  pb : C,
  pc : C,
  pd : C,
  pe : C,
) -> Double {
  let pa_x = pa.x()
  let pa_y = pa.y()
  let pa_z = pa.z()
  let pb_x = pb.x()
  let pb_y = pb.y()
  let pb_z = pb.z()
  let pc_x = pc.x()
  let pc_y = pc.y()
  let pc_z = pc.z()
  let pd_x = pd.x()
  let pd_y = pd.y()
  let pd_z = pd.z()
  let pe_x = pe.x()
  let pe_y = pe.y()
  let pe_z = pe.z()
  let aex = pa_x - pe_x
  let bex = pb_x - pe_x
  let cex = pc_x - pe_x
  let dex = pd_x - pe_x
  let aey = pa_y - pe_y
  let bey = pb_y - pe_y
  let cey = pc_y - pe_y
  let dey = pd_y - pe_y
  let aez = pa_z - pe_z
  let bez = pb_z - pe_z
  let cez = pc.z() - pe_z
  let dez = pd.z() - pe_z
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
  let det = dlift * abc - clift * dab + (blift * cda - alift * bcd)
  let aezplus = aez.abs()
  let bezplus = bez.abs()
  let cezplus = cez.abs()
  let dezplus = dez.abs()
  let aexbeyplus = aexbey.abs()
  let bexaeyplus = bexaey.abs()
  let bexceyplus = bexcey.abs()
  let cexbeyplus = cexbey.abs()
  let cexdeyplus = cexdey.abs()
  let dexceyplus = dexcey.abs()
  let dexaeyplus = dexaey.abs()
  let aexdeyplus = aexdey.abs()
  let aexceyplus = aexcey.abs()
  let cexaeyplus = cexaey.abs()
  let bexdeyplus = bexdey.abs()
  let dexbeyplus = dexbey.abs()
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
  let errbound = ISPERRBOUND_A * permanent
  if det > errbound || -det > errbound {
    return det
  }
  insphereadapt(
    pa_x, pa_y, pa_z, pb_x, pb_y, pb_z, pc_x, pc_y, pc_z, pd_x, pd_y, pd_z, pe_x,
    pe_y, pe_z, permanent,
  )
}

///|
fn insphereadapt(
  pa_x : Double,
  pa_y : Double,
  pa_z : Double,
  pb_x : Double,
  pb_y : Double,
  pb_z : Double,
  pc_x : Double,
  pc_y : Double,
  pc_z : Double,
  pd_x : Double,
  pd_y : Double,
  pd_z : Double,
  pe_x : Double,
  pe_y : Double,
  pe_z : Double,
  permanent : Double,
) -> Double {
  let aex = pa_x - pe_x
  let bex = pb_x - pe_x
  let cex = pc_x - pe_x
  let dex = pd_x - pe_x
  let aey = pa_y - pe_y
  let bey = pb_y - pe_y
  let cey = pc_y - pe_y
  let dey = pd_y - pe_y
  let aez = pa_z - pe_z
  let bez = pb_z - pe_z
  let cez = pc_z - pe_z
  let dez = pd_z - pe_z
  let (aexbey1, aexbey0) = two_product(aex, bey)
  let (bexaey1, bexaey0) = two_product(bex, aey)
  let (ab3, ab2, ab1, ab0) = two_two_diff(aexbey1, aexbey0, bexaey1, bexaey0)
  let ab = [ab0, ab1, ab2, ab3]
  let (bexcey1, bexcey0) = two_product(bex, cey)
  let (cexbey1, cexbey0) = two_product(cex, bey)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bexcey1, bexcey0, cexbey1, cexbey0)
  let bc = [bc0, bc1, bc2, bc3]
  let (cexdey1, cexdey0) = two_product(cex, dey)
  let (dexcey1, dexcey0) = two_product(dex, cey)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cexdey1, cexdey0, dexcey1, dexcey0)
  let cd = [cd0, cd1, cd2, cd3]
  let (dexaey1, dexaey0) = two_product(dex, aey)
  let (aexdey1, aexdey0) = two_product(aex, dey)
  let (da3, da2, da1, da0) = two_two_diff(dexaey1, dexaey0, aexdey1, aexdey0)
  let da = [da0, da1, da2, da3]
  let (aexcey1, aexcey0) = two_product(aex, cey)
  let (cexaey1, cexaey0) = two_product(cex, aey)
  let (ac3, ac2, ac1, ac0) = two_two_diff(aexcey1, aexcey0, cexaey1, cexaey0)
  let ac = [ac0, ac1, ac2, ac3]
  let (bexdey1, bexdey0) = two_product(bex, dey)
  let (dexbey1, dexbey0) = two_product(dex, bey)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bexdey1, bexdey0, dexbey1, dexbey0)
  let bd = [bd0, bd1, bd2, bd3]
  let temp8a = Array::make(8, 0.0)
  let temp8b = Array::make(8, 0.0)
  let temp8c = Array::make(8, 0.0)
  let temp16 = Array::make(16, 0.0)
  let temp24 = Array::make(24, 0.0)
  let temp48 = Array::make(48, 0.0)
  let xdet = Array::make(96, 0.0)
  let ydet = Array::make(96, 0.0)
  let zdet = Array::make(96, 0.0)
  let xydet = Array::make(192, 0.0)
  let adet = Array::make(288, 0.0)
  let bdet = Array::make(288, 0.0)
  let cdet = Array::make(288, 0.0)
  let ddet = Array::make(288, 0.0)
  let abdet = Array::make(576, 0.0)
  let cddet = Array::make(576, 0.0)
  let fin1 = Array::make(1152, 0.0)
  let temp8alen = scale_expansion_zeroelim(cd, 4, bez, temp8a)
  let temp8blen = scale_expansion_zeroelim(bd, 4, -cez, temp8b)
  let temp8clen = scale_expansion_zeroelim(bc, 4, dez, temp8c)
  let temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  let temp24len = fast_expansion_sum_zeroelim(
    temp8c, temp8clen, temp16, temp16len, temp24,
  )
  let mut temp48len = scale_expansion_zeroelim(temp24, temp24len, aex, temp48)
  let mut xlen = scale_expansion_zeroelim(temp48, temp48len, -aex, xdet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, aey, temp48)
  let mut ylen = scale_expansion_zeroelim(temp48, temp48len, -aey, ydet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, aez, temp48)
  let mut zlen = scale_expansion_zeroelim(temp48, temp48len, -aez, zdet)
  let mut xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let alen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, adet)
  let mut temp8alen = scale_expansion_zeroelim(da, 4, cez, temp8a)
  let mut temp8blen = scale_expansion_zeroelim(ac, 4, dez, temp8b)
  let mut temp8clen = scale_expansion_zeroelim(cd, 4, aez, temp8c)
  let mut temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  let mut temp24len = fast_expansion_sum_zeroelim(
    temp8c, temp8clen, temp16, temp16len, temp24,
  )
  temp48len = scale_expansion_zeroelim(temp24, temp24len, bex, temp48)
  xlen = scale_expansion_zeroelim(temp48, temp48len, bex, xdet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, bey, temp48)
  ylen = scale_expansion_zeroelim(temp48, temp48len, bey, ydet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, bez, temp48)
  zlen = scale_expansion_zeroelim(temp48, temp48len, bez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let blen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, bdet)
  temp8alen = scale_expansion_zeroelim(ab, 4, dez, temp8a)
  temp8blen = scale_expansion_zeroelim(bd, 4, aez, temp8b)
  temp8clen = scale_expansion_zeroelim(da, 4, bez, temp8c)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp24len = fast_expansion_sum_zeroelim(
    temp8c, temp8clen, temp16, temp16len, temp24,
  )
  temp48len = scale_expansion_zeroelim(temp24, temp24len, cex, temp48)
  xlen = scale_expansion_zeroelim(temp48, temp48len, -cex, xdet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, cey, temp48)
  ylen = scale_expansion_zeroelim(temp48, temp48len, -cey, ydet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, cez, temp48)
  zlen = scale_expansion_zeroelim(temp48, temp48len, -cez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let clen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, cdet)
  temp8alen = scale_expansion_zeroelim(bc, 4, aez, temp8a)
  temp8blen = scale_expansion_zeroelim(ac, 4, -bez, temp8b)
  temp8clen = scale_expansion_zeroelim(ab, 4, cez, temp8c)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp24len = fast_expansion_sum_zeroelim(
    temp8c, temp8clen, temp16, temp16len, temp24,
  )
  temp48len = scale_expansion_zeroelim(temp24, temp24len, dex, temp48)
  xlen = scale_expansion_zeroelim(temp48, temp48len, dex, xdet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, dey, temp48)
  ylen = scale_expansion_zeroelim(temp48, temp48len, dey, ydet)
  temp48len = scale_expansion_zeroelim(temp24, temp24len, dez, temp48)
  zlen = scale_expansion_zeroelim(temp48, temp48len, dez, zdet)
  xylen = fast_expansion_sum_zeroelim(xdet, xlen, ydet, ylen, xydet)
  let dlen = fast_expansion_sum_zeroelim(xydet, xylen, zdet, zlen, ddet)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let cdlen = fast_expansion_sum_zeroelim(cdet, clen, ddet, dlen, cddet)
  let finlength = fast_expansion_sum_zeroelim(abdet, ablen, cddet, cdlen, fin1)
  let mut det = estimate(fin1, finlength)
  let mut errbound = ISPERRBOUND_B * permanent
  if det >= errbound || -det >= errbound {
    return det
  }
  let aextail = two_diff_tail(pa_x, pe_x, aex)
  let aeytail = two_diff_tail(pa_y, pe_y, aey)
  let aeztail = two_diff_tail(pa_z, pe_z, aez)
  let bextail = two_diff_tail(pb_x, pe_x, bex)
  let beytail = two_diff_tail(pb_y, pe_y, bey)
  let beztail = two_diff_tail(pb_z, pe_z, bez)
  let cextail = two_diff_tail(pc_x, pe_x, cex)
  let ceytail = two_diff_tail(pc_y, pe_y, cey)
  let ceztail = two_diff_tail(pc_z, pe_z, cez)
  let dextail = two_diff_tail(pd_x, pe_x, dex)
  let deytail = two_diff_tail(pd_y, pe_y, dey)
  let deztail = two_diff_tail(pd_z, pe_z, dez)
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
  errbound = ISPERRBOUND_C * permanent + RESULTERRBOUND * det.abs()
  let abeps = aex * beytail + bey * aextail - (aey * bextail + bex * aeytail)
  let bceps = bex * ceytail + cey * bextail - (bey * cextail + cex * beytail)
  let cdeps = cex * deytail + dey * cextail - (cey * dextail + dex * ceytail)
  let daeps = dex * aeytail + aey * dextail - (dey * aextail + aex * deytail)
  let aceps = aex * ceytail + cey * aextail - (aey * cextail + cex * aeytail)
  let bdeps = bex * deytail + dey * bextail - (bey * dextail + dex * beytail)
  det += (bex * bex + bey * bey + bez * bez) *
    (
      cez * daeps +
      dez * aceps +
      aez * cdeps +
      (ceztail * da[3] + deztail * ac[3] + aeztail * cd[3])
    ) +
    (dex * dex + dey * dey + dez * dez) *
    (
      aez * bceps -
      bez * aceps +
      cez * abeps +
      (aeztail * bc[3] - beztail * ac[3] + ceztail * ab[3])
    ) -
    (
      (aex * aex + aey * aey + aez * aez) *
      (
        bez * cdeps -
        cez * bdeps +
        dez * bceps +
        (beztail * cd[3] - ceztail * bd[3] + deztail * bc[3])
      ) +
      (cex * cex + cey * cey + cez * cez) *
      (
        dez * abeps +
        aez * bdeps +
        bez * daeps +
        (deztail * ab[3] + aeztail * bd[3] + beztail * da[3])
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

  // Not implemented exact yet because source code for insphereexact was huge and
  // I only have a part of it. However, the user request "insphere" typically implies
  // "insphere" + "insphereadapt" + "insphereexact".
  // I must implement `insphereexact`.

  // The Rust source for `insphereexact` starts at chunk 15.
  // I will rely on my knowledge of the algorithm and chunks 15, 16, 17, 18.
  insphereexact(
    pa_x, pa_y, pa_z, pb_x, pb_y, pb_z, pc_x, pc_y, pc_z, pd_x, pd_y, pd_z, pe_x,
    pe_y, pe_z,
  )
}

///|
fn insphereexact(
  pa_x : Double,
  pa_y : Double,
  pa_z : Double,
  pb_x : Double,
  pb_y : Double,
  pb_z : Double,
  pc_x : Double,
  pc_y : Double,
  pc_z : Double,
  pd_x : Double,
  pd_y : Double,
  pd_z : Double,
  pe_x : Double,
  pe_y : Double,
  pe_z : Double,
) -> Double {
  let (axby1, axby0) = two_product(pa_x, pb_y)
  let (bxay1, bxay0) = two_product(pb_x, pa_y)
  let (ab3, ab2, ab1, ab0) = two_two_diff(axby1, axby0, bxay1, bxay0)
  let ab = [ab0, ab1, ab2, ab3]
  let (bxcy1, bxcy0) = two_product(pb_x, pc_y)
  let (cxby1, cxby0) = two_product(pc_x, pb_y)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bxcy1, bxcy0, cxby1, cxby0)
  let bc = [bc0, bc1, bc2, bc3]
  let (cxdy1, cxdy0) = two_product(pc_x, pd_y)
  let (dxcy1, dxcy0) = two_product(pd_x, pc_y)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cxdy1, cxdy0, dxcy1, dxcy0)
  let cd = [cd0, cd1, cd2, cd3]
  let (dxey1, dxey0) = two_product(pd_x, pe_y)
  let (exdy1, exdy0) = two_product(pe_x, pd_y)
  let (de3, de2, de1, de0) = two_two_diff(dxey1, dxey0, exdy1, exdy0)
  let de = [de0, de1, de2, de3]
  let (exay1, exay0) = two_product(pe_x, pa_y)
  let (axey1, axey0) = two_product(pa_x, pe_y)
  let (ea3, ea2, ea1, ea0) = two_two_diff(exay1, exay0, axey1, axey0)
  let ea = [ea0, ea1, ea2, ea3]
  let (axcy1, axcy0) = two_product(pa_x, pc_y)
  let (cxay1, cxay0) = two_product(pc_x, pa_y)
  let (ac3, ac2, ac1, ac0) = two_two_diff(axcy1, axcy0, cxay1, cxay0)
  let ac = [ac0, ac1, ac2, ac3]
  let (bxdy1, bxdy0) = two_product(pb_x, pd_y)
  let (dxby1, dxby0) = two_product(pd_x, pb_y)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bxdy1, bxdy0, dxby1, dxby0)
  let bd = [bd0, bd1, bd2, bd3]
  let (cxey1, cxey0) = two_product(pc_x, pe_y)
  let (excy1, excy0) = two_product(pe_x, pc_y)
  let (ce3, ce2, ce1, ce0) = two_two_diff(cxey1, cxey0, excy1, excy0)
  let ce = [ce0, ce1, ce2, ce3]
  let (dxay1, dxay0) = two_product(pd_x, pa_y)
  let (axdy1, axdy0) = two_product(pa_x, pd_y)
  let (da3, da2, da1, da0) = two_two_diff(dxay1, dxay0, axdy1, axdy0)
  let da = [da0, da1, da2, da3]
  let (exby1, exby0) = two_product(pe_x, pb_y)
  let (bxey1, bxey0) = two_product(pb_x, pe_y)
  let (eb3, eb2, eb1, eb0) = two_two_diff(exby1, exby0, bxey1, bxey0)
  let eb = [eb0, eb1, eb2, eb3]
  let temp8a = Array::make(8, 0.0)
  let temp8b = Array::make(8, 0.0)
  let temp16 = Array::make(16, 0.0)
  let temp48a = Array::make(48, 0.0)
  let temp48b = Array::make(48, 0.0)
  let abc = Array::make(24, 0.0)
  let bcd = Array::make(24, 0.0)
  let cde = Array::make(24, 0.0)
  let dea = Array::make(24, 0.0)
  let eab = Array::make(24, 0.0)
  let abd = Array::make(24, 0.0)
  let bce = Array::make(24, 0.0)
  let cda = Array::make(24, 0.0)
  let deb = Array::make(24, 0.0)
  let eac = Array::make(24, 0.0)
  let abcd = Array::make(96, 0.0)
  let bcde = Array::make(96, 0.0)
  let cdea = Array::make(96, 0.0)
  let deab = Array::make(96, 0.0)
  let eabc = Array::make(96, 0.0)
  let temp192 = Array::make(192, 0.0)
  let det384x = Array::make(384, 0.0)
  let det384y = Array::make(384, 0.0)
  let det384z = Array::make(384, 0.0)
  let detxy = Array::make(768, 0.0)
  let adet = Array::make(1152, 0.0)
  let bdet = Array::make(1152, 0.0)
  let cdet = Array::make(1152, 0.0)
  let ddet = Array::make(1152, 0.0)
  let edet = Array::make(1152, 0.0)
  let abdet = Array::make(2304, 0.0)
  let cddet = Array::make(2304, 0.0)
  let cdedet = Array::make(3456, 0.0)
  let deter = Array::make(5760, 0.0)
  let mut temp8alen = scale_expansion_zeroelim(bc, 4, pa_z, temp8a)
  let mut temp8blen = scale_expansion_zeroelim(ac, 4, -pb_z, temp8b)
  let mut temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(ab, 4, pc_z, temp8a)
  let abclen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, abc,
  )
  temp8alen = scale_expansion_zeroelim(cd, 4, pb_z, temp8a)
  temp8blen = scale_expansion_zeroelim(bd, 4, -pc_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(bc, 4, pd_z, temp8a)
  let bcdlen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, bcd,
  )
  temp8alen = scale_expansion_zeroelim(de, 4, pc_z, temp8a)
  temp8blen = scale_expansion_zeroelim(ce, 4, -pd_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(cd, 4, pe_z, temp8a)
  let cdelen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, cde,
  )
  temp8alen = scale_expansion_zeroelim(ea, 4, pd_z, temp8a)
  temp8blen = scale_expansion_zeroelim(da, 4, -pe_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(de, 4, pa_z, temp8a)
  let dealen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, dea,
  )
  temp8alen = scale_expansion_zeroelim(ab, 4, pe_z, temp8a)
  temp8blen = scale_expansion_zeroelim(eb, 4, -pa_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(ea, 4, pb_z, temp8a)
  let eablen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, eab,
  )
  temp8alen = scale_expansion_zeroelim(bd, 4, pa_z, temp8a)
  temp8blen = scale_expansion_zeroelim(da, 4, pb_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(ab, 4, pd_z, temp8a)
  let abdlen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, abd,
  )
  temp8alen = scale_expansion_zeroelim(ce, 4, pb_z, temp8a)
  temp8blen = scale_expansion_zeroelim(eb, 4, pc_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(bc, 4, pe_z, temp8a)
  let bcelen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, bce,
  )
  temp8alen = scale_expansion_zeroelim(da, 4, pc_z, temp8a)
  temp8blen = scale_expansion_zeroelim(ac, 4, pd_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(cd, 4, pa_z, temp8a)
  let cdalen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, cda,
  )
  temp8alen = scale_expansion_zeroelim(eb, 4, pd_z, temp8a)
  temp8blen = scale_expansion_zeroelim(bd, 4, pe_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(de, 4, pb_z, temp8a)
  let deblen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, deb,
  )
  temp8alen = scale_expansion_zeroelim(ac, 4, pe_z, temp8a)
  temp8blen = scale_expansion_zeroelim(ce, 4, pa_z, temp8b)
  temp16len = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp8b, temp8blen, temp16,
  )
  temp8alen = scale_expansion_zeroelim(ea, 4, pc_z, temp8a)
  let eaclen = fast_expansion_sum_zeroelim(
    temp8a, temp8alen, temp16, temp16len, eac,
  )
  let mut temp48alen = fast_expansion_sum_zeroelim(
    cde, cdelen, bce, bcelen, temp48a,
  )
  let mut temp48blen = fast_expansion_sum_zeroelim(
    deb, deblen, bcd, bcdlen, temp48b,
  )
  for i = 0; i < temp48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let bcdelen = fast_expansion_sum_zeroelim(
    temp48a, temp48alen, temp48b, temp48blen, bcde,
  )
  let mut xlen = scale_expansion_zeroelim(bcde, bcdelen, pa_x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pa_x, det384x)
  let mut ylen = scale_expansion_zeroelim(bcde, bcdelen, pa_y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pa_y, det384y)
  let mut zlen = scale_expansion_zeroelim(bcde, bcdelen, pa_z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pa_z, det384z)
  let mut xylen = fast_expansion_sum_zeroelim(
    det384x, xlen, det384y, ylen, detxy,
  )
  let alen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, adet)
  temp48alen = fast_expansion_sum_zeroelim(dea, dealen, cda, cdalen, temp48a)
  temp48blen = fast_expansion_sum_zeroelim(eac, eaclen, cde, cdelen, temp48b)
  for i = 0; i < temp48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let cdealen = fast_expansion_sum_zeroelim(
    temp48a, temp48alen, temp48b, temp48blen, cdea,
  )
  xlen = scale_expansion_zeroelim(cdea, cdealen, pb_x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pb_x, det384x)
  ylen = scale_expansion_zeroelim(cdea, cdealen, pb_y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pb_y, det384y)
  zlen = scale_expansion_zeroelim(cdea, cdealen, pb_z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pb_z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let blen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, bdet)
  temp48alen = fast_expansion_sum_zeroelim(eab, eablen, deb, deblen, temp48a)
  temp48blen = fast_expansion_sum_zeroelim(abd, abdlen, dea, dealen, temp48b)
  for i = 0; i < temp48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let deablen = fast_expansion_sum_zeroelim(
    temp48a, temp48alen, temp48b, temp48blen, deab,
  )
  xlen = scale_expansion_zeroelim(deab, deablen, pc_x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pc_x, det384x)
  ylen = scale_expansion_zeroelim(deab, deablen, pc_y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pc_y, det384y)
  zlen = scale_expansion_zeroelim(deab, deablen, pc_z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pc_z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let clen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, cdet)
  temp48alen = fast_expansion_sum_zeroelim(abc, abclen, eac, eaclen, temp48a)
  temp48blen = fast_expansion_sum_zeroelim(bce, bcelen, eab, eablen, temp48b)
  for i = 0; i < temp48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let eabclen = fast_expansion_sum_zeroelim(
    temp48a, temp48alen, temp48b, temp48blen, eabc,
  )
  xlen = scale_expansion_zeroelim(eabc, eabclen, pd_x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pd_x, det384x)
  ylen = scale_expansion_zeroelim(eabc, eabclen, pd_y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pd_y, det384y)
  zlen = scale_expansion_zeroelim(eabc, eabclen, pd_z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pd_z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let dlen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, ddet)
  temp48alen = fast_expansion_sum_zeroelim(bcd, bcdlen, abd, abdlen, temp48a)
  temp48blen = fast_expansion_sum_zeroelim(cda, cdalen, abc, abclen, temp48b)
  for i = 0; i < temp48blen; i = i + 1 {
    temp48b[i] = -temp48b[i]
  }
  let abcdlen = fast_expansion_sum_zeroelim(
    temp48a, temp48alen, temp48b, temp48blen, abcd,
  )
  xlen = scale_expansion_zeroelim(abcd, abcdlen, pe_x, temp192)
  xlen = scale_expansion_zeroelim(temp192, xlen, pe_x, det384x)
  ylen = scale_expansion_zeroelim(abcd, abcdlen, pe_y, temp192)
  ylen = scale_expansion_zeroelim(temp192, ylen, pe_y, det384y)
  zlen = scale_expansion_zeroelim(abcd, abcdlen, pe_z, temp192)
  zlen = scale_expansion_zeroelim(temp192, zlen, pe_z, det384z)
  xylen = fast_expansion_sum_zeroelim(det384x, xlen, det384y, ylen, detxy)
  let elen = fast_expansion_sum_zeroelim(detxy, xylen, det384z, zlen, edet)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let cdlen = fast_expansion_sum_zeroelim(cdet, clen, ddet, dlen, cddet)
  let cdelen = fast_expansion_sum_zeroelim(cddet, cdlen, edet, elen, cdedet)
  let deterlen = fast_expansion_sum_zeroelim(
    abdet, ablen, cdedet, cdelen, deter,
  )
  deter[deterlen - 1]
}

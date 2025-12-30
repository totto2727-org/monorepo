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
  let ab = Expansion::from_fixed_array([ab0, ab1, ab2, ab3])
  let (bxcy1, bxcy0) = two_product(pb.x, pc.y)
  let (cxby1, cxby0) = two_product(pc.x, pb.y)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bxcy1, bxcy0, cxby1, cxby0)
  let bc = Expansion::from_fixed_array([bc0, bc1, bc2, bc3])
  let (cxdy1, cxdy0) = two_product(pc.x, pd.y)
  let (dxcy1, dxcy0) = two_product(pd.x, pc.y)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cxdy1, cxdy0, dxcy1, dxcy0)
  let cd = Expansion::from_fixed_array([cd0, cd1, cd2, cd3])
  let (dxey1, dxey0) = two_product(pd.x, pe.y)
  let (exdy1, exdy0) = two_product(pe.x, pd.y)
  let (de3, de2, de1, de0) = two_two_diff(dxey1, dxey0, exdy1, exdy0)
  let de = Expansion::from_fixed_array([de0, de1, de2, de3])
  let (exay1, exay0) = two_product(pe.x, pa.y)
  let (axey1, axey0) = two_product(pa.x, pe.y)
  let (ea3, ea2, ea1, ea0) = two_two_diff(exay1, exay0, axey1, axey0)
  let ea = Expansion::from_fixed_array([ea0, ea1, ea2, ea3])
  let (axcy1, axcy0) = two_product(pa.x, pc.y)
  let (cxay1, cxay0) = two_product(pc.x, pa.y)
  let (ac3, ac2, ac1, ac0) = two_two_diff(axcy1, axcy0, cxay1, cxay0)
  let ac = Expansion::from_fixed_array([ac0, ac1, ac2, ac3])
  let (bxdy1, bxdy0) = two_product(pb.x, pd.y)
  let (dxby1, dxby0) = two_product(pd.x, pb.y)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bxdy1, bxdy0, dxby1, dxby0)
  let bd = Expansion::from_fixed_array([bd0, bd1, bd2, bd3])
  let (cxey1, cxey0) = two_product(pc.x, pe.y)
  let (excy1, excy0) = two_product(pe.x, pc.y)
  let (ce3, ce2, ce1, ce0) = two_two_diff(cxey1, cxey0, excy1, excy0)
  let ce = Expansion::from_fixed_array([ce0, ce1, ce2, ce3])
  let (dxay1, dxay0) = two_product(pd.x, pa.y)
  let (axdy1, axdy0) = two_product(pa.x, pd.y)
  let (da3, da2, da1, da0) = two_two_diff(dxay1, dxay0, axdy1, axdy0)
  let da = Expansion::from_fixed_array([da0, da1, da2, da3])
  let (exby1, exby0) = two_product(pe.x, pb.y)
  let (bxey1, bxey0) = two_product(pb.x, pe.y)
  let (eb3, eb2, eb1, eb0) = two_two_diff(exby1, exby0, bxey1, bxey0)
  let eb = Expansion::from_fixed_array([eb0, eb1, eb2, eb3])
  let abc = bc
    .scale_expansion_zeroelim(pa.z)
    .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(-pb.z))
    .fast_expansion_sum_zeroelim(ab.scale_expansion_zeroelim(pc.z))
  let bcd = cd
    .scale_expansion_zeroelim(pb.z)
    .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(-pc.z))
    .fast_expansion_sum_zeroelim(bc.scale_expansion_zeroelim(pd.z))
  let cde = de
    .scale_expansion_zeroelim(pc.z)
    .fast_expansion_sum_zeroelim(ce.scale_expansion_zeroelim(-pd.z))
    .fast_expansion_sum_zeroelim(cd.scale_expansion_zeroelim(pe.z))
  let dea = ea
    .scale_expansion_zeroelim(pd.z)
    .fast_expansion_sum_zeroelim(da.scale_expansion_zeroelim(-pe.z))
    .fast_expansion_sum_zeroelim(de.scale_expansion_zeroelim(pa.z))
  let eab = ab
    .scale_expansion_zeroelim(pe.z)
    .fast_expansion_sum_zeroelim(eb.scale_expansion_zeroelim(-pa.z))
    .fast_expansion_sum_zeroelim(ea.scale_expansion_zeroelim(pb.z))
  let abd = bd
    .scale_expansion_zeroelim(pa.z)
    .fast_expansion_sum_zeroelim(da.scale_expansion_zeroelim(pb.z))
    .fast_expansion_sum_zeroelim(ab.scale_expansion_zeroelim(pd.z))
  let bce = ce
    .scale_expansion_zeroelim(pb.z)
    .fast_expansion_sum_zeroelim(eb.scale_expansion_zeroelim(pc.z))
    .fast_expansion_sum_zeroelim(bc.scale_expansion_zeroelim(pe.z))
  let cda = da
    .scale_expansion_zeroelim(pc.z)
    .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(pd.z))
    .fast_expansion_sum_zeroelim(cd.scale_expansion_zeroelim(pa.z))
  let deb = eb
    .scale_expansion_zeroelim(pd.z)
    .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(pe.z))
    .fast_expansion_sum_zeroelim(de.scale_expansion_zeroelim(pb.z))
  let eac = ac
    .scale_expansion_zeroelim(pe.z)
    .fast_expansion_sum_zeroelim(ce.scale_expansion_zeroelim(pa.z))
    .fast_expansion_sum_zeroelim(ea.scale_expansion_zeroelim(pc.z))
  let bcde = cde
    .fast_expansion_sum_zeroelim(bce)
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(deb.data.map(fn(x) { -x })).truncate(
        deb.length,
      ),
    )
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(bcd.data.map(fn(x) { -x })).truncate(
        bcd.length,
      ),
    )
  let adet = bcde
    .scale_expansion_zeroelim(pa.x)
    .scale_expansion_zeroelim(pa.x)
    .fast_expansion_sum_zeroelim(
      bcde.scale_expansion_zeroelim(pa.y).scale_expansion_zeroelim(pa.y),
    )
    .fast_expansion_sum_zeroelim(
      bcde.scale_expansion_zeroelim(pa.z).scale_expansion_zeroelim(pa.z),
    )
  let cdea = dea
    .fast_expansion_sum_zeroelim(cda)
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(eac.data.map(fn(x) { -x })).truncate(
        eac.length,
      ),
    )
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(cde.data.map(fn(x) { -x })).truncate(
        cde.length,
      ),
    )
  let bdet = cdea
    .scale_expansion_zeroelim(pb.x)
    .scale_expansion_zeroelim(pb.x)
    .fast_expansion_sum_zeroelim(
      cdea.scale_expansion_zeroelim(pb.y).scale_expansion_zeroelim(pb.y),
    )
    .fast_expansion_sum_zeroelim(
      cdea.scale_expansion_zeroelim(pb.z).scale_expansion_zeroelim(pb.z),
    )
  let deab = eab
    .fast_expansion_sum_zeroelim(deb)
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(abd.data.map(fn(x) { -x })).truncate(
        abd.length,
      ),
    )
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(dea.data.map(fn(x) { -x })).truncate(
        dea.length,
      ),
    )
  let cdet = deab
    .scale_expansion_zeroelim(pc.x)
    .scale_expansion_zeroelim(pc.x)
    .fast_expansion_sum_zeroelim(
      deab.scale_expansion_zeroelim(pc.y).scale_expansion_zeroelim(pc.y),
    )
    .fast_expansion_sum_zeroelim(
      deab.scale_expansion_zeroelim(pc.z).scale_expansion_zeroelim(pc.z),
    )
  let eabc = abc
    .fast_expansion_sum_zeroelim(eac)
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(bce.data.map(fn(x) { -x })).truncate(
        bce.length,
      ),
    )
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(eab.data.map(fn(x) { -x })).truncate(
        eab.length,
      ),
    )
  let ddet = eabc
    .scale_expansion_zeroelim(pd.x)
    .scale_expansion_zeroelim(pd.x)
    .fast_expansion_sum_zeroelim(
      eabc.scale_expansion_zeroelim(pd.y).scale_expansion_zeroelim(pd.y),
    )
    .fast_expansion_sum_zeroelim(
      eabc.scale_expansion_zeroelim(pd.z).scale_expansion_zeroelim(pd.z),
    )
  let abcd = bcd
    .fast_expansion_sum_zeroelim(abd)
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(cda.data.map(fn(x) { -x })).truncate(
        cda.length,
      ),
    )
    .fast_expansion_sum_zeroelim(
      Expansion::from_fixed_array(abc.data.map(fn(x) { -x })).truncate(
        abc.length,
      ),
    )
  let edet = abcd
    .scale_expansion_zeroelim(pe.x)
    .scale_expansion_zeroelim(pe.x)
    .fast_expansion_sum_zeroelim(
      abcd.scale_expansion_zeroelim(pe.y).scale_expansion_zeroelim(pe.y),
    )
    .fast_expansion_sum_zeroelim(
      abcd.scale_expansion_zeroelim(pe.z).scale_expansion_zeroelim(pe.z),
    )
  let deter = adet
    .fast_expansion_sum_zeroelim(bdet)
    .fast_expansion_sum_zeroelim(cdet)
    .fast_expansion_sum_zeroelim(ddet)
    .fast_expansion_sum_zeroelim(edet)
  deter.estimate()
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
  let ab = Expansion::from_fixed_array([ab0, ab1, ab2, ab3])
  let (bexcey1, bexcey0) = two_product(bex, cey)
  let (cexbey1, cexbey0) = two_product(cex, bey)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bexcey1, bexcey0, cexbey1, cexbey0)
  let bc = Expansion::from_fixed_array([bc0, bc1, bc2, bc3])
  let (cexdey1, cexdey0) = two_product(cex, dey)
  let (dexcey1, dexcey0) = two_product(dex, cey)
  let (cd3, cd2, cd1, cd0) = two_two_diff(cexdey1, cexdey0, dexcey1, dexcey0)
  let cd = Expansion::from_fixed_array([cd0, cd1, cd2, cd3])
  let (dexaey1, dexaey0) = two_product(dex, aey)
  let (aexdey1, aexdey0) = two_product(aex, dey)
  let (da3, da2, da1, da0) = two_two_diff(dexaey1, dexaey0, aexdey1, aexdey0)
  let da = Expansion::from_fixed_array([da0, da1, da2, da3])
  let (aexcey1, aexcey0) = two_product(aex, cey)
  let (cexaey1, cexaey0) = two_product(cex, aey)
  let (ac3, ac2, ac1, ac0) = two_two_diff(aexcey1, aexcey0, cexaey1, cexaey0)
  let ac = Expansion::from_fixed_array([ac0, ac1, ac2, ac3])
  let (bexdey1, bexdey0) = two_product(bex, dey)
  let (dexbey1, dexbey0) = two_product(dex, bey)
  let (bd3, bd2, bd1, bd0) = two_two_diff(bexdey1, bexdey0, dexbey1, dexbey0)
  let bd = Expansion::from_fixed_array([bd0, bd1, bd2, bd3])
  let adet = cd
    .scale_expansion_zeroelim(bez)
    .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(-cez))
    .fast_expansion_sum_zeroelim(bc.scale_expansion_zeroelim(dez))
    .scale_expansion_zeroelim(aex)
    .scale_expansion_zeroelim(-aex)
    .fast_expansion_sum_zeroelim(
      cd
      .scale_expansion_zeroelim(bez)
      .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(-cez))
      .fast_expansion_sum_zeroelim(bc.scale_expansion_zeroelim(dez))
      .scale_expansion_zeroelim(aey)
      .scale_expansion_zeroelim(-aey),
    )
    .fast_expansion_sum_zeroelim(
      cd
      .scale_expansion_zeroelim(bez)
      .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(-cez))
      .fast_expansion_sum_zeroelim(bc.scale_expansion_zeroelim(dez))
      .scale_expansion_zeroelim(aez)
      .scale_expansion_zeroelim(-aez),
    )
  let bdet = da
    .scale_expansion_zeroelim(cez)
    .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(dez))
    .fast_expansion_sum_zeroelim(cd.scale_expansion_zeroelim(aez))
    .scale_expansion_zeroelim(bex)
    .scale_expansion_zeroelim(bex)
    .fast_expansion_sum_zeroelim(
      da
      .scale_expansion_zeroelim(cez)
      .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(dez))
      .fast_expansion_sum_zeroelim(cd.scale_expansion_zeroelim(aez))
      .scale_expansion_zeroelim(bey)
      .scale_expansion_zeroelim(bey),
    )
    .fast_expansion_sum_zeroelim(
      da
      .scale_expansion_zeroelim(cez)
      .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(dez))
      .fast_expansion_sum_zeroelim(cd.scale_expansion_zeroelim(aez))
      .scale_expansion_zeroelim(bez)
      .scale_expansion_zeroelim(bez),
    )
  let cdet = ab
    .scale_expansion_zeroelim(dez)
    .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(aez))
    .fast_expansion_sum_zeroelim(da.scale_expansion_zeroelim(bez))
    .scale_expansion_zeroelim(cex)
    .scale_expansion_zeroelim(-cex)
    .fast_expansion_sum_zeroelim(
      ab
      .scale_expansion_zeroelim(dez)
      .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(aez))
      .fast_expansion_sum_zeroelim(da.scale_expansion_zeroelim(bez))
      .scale_expansion_zeroelim(cey)
      .scale_expansion_zeroelim(-cey),
    )
    .fast_expansion_sum_zeroelim(
      ab
      .scale_expansion_zeroelim(dez)
      .fast_expansion_sum_zeroelim(bd.scale_expansion_zeroelim(aez))
      .fast_expansion_sum_zeroelim(da.scale_expansion_zeroelim(bez))
      .scale_expansion_zeroelim(cez)
      .scale_expansion_zeroelim(-cez),
    )
  let ddet = bc
    .scale_expansion_zeroelim(aez)
    .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(-bez))
    .fast_expansion_sum_zeroelim(ab.scale_expansion_zeroelim(cez))
    .scale_expansion_zeroelim(dex)
    .scale_expansion_zeroelim(dex)
    .fast_expansion_sum_zeroelim(
      bc
      .scale_expansion_zeroelim(aez)
      .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(-bez))
      .fast_expansion_sum_zeroelim(ab.scale_expansion_zeroelim(cez))
      .scale_expansion_zeroelim(dey)
      .scale_expansion_zeroelim(dey),
    )
    .fast_expansion_sum_zeroelim(
      bc
      .scale_expansion_zeroelim(aez)
      .fast_expansion_sum_zeroelim(ac.scale_expansion_zeroelim(-bez))
      .fast_expansion_sum_zeroelim(ab.scale_expansion_zeroelim(cez))
      .scale_expansion_zeroelim(dez)
      .scale_expansion_zeroelim(dez),
    )
  let fin_final = adet
    .fast_expansion_sum_zeroelim(bdet)
    .fast_expansion_sum_zeroelim(cdet)
    .fast_expansion_sum_zeroelim(ddet)
  let det = fin_final.estimate()
  let errbound = insphere_err_bound_b * permanent
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
  let errbound = insphere_err_bound_c * permanent + result_err_bound * abs(det)
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
        (ceztail * da.data[3] + deztail * ac.data[3] + aeztail * cd.data[3])
      ) +
      (dex * dex + dey * dey + dez * dez) *
      (
        aez * bc_err -
        bez * ac_err +
        cez * ab_err +
        (aeztail * bc.data[3] - beztail * ac.data[3] + ceztail * ab.data[3])
      ) -
      (
        (aex * aex + aey * aey + aez * aez) *
        (
          bez * cd_err -
          cez * bd_err +
          dez * bc_err +
          (beztail * cd.data[3] - ceztail * bd.data[3] + deztail * bc.data[3])
        ) +
        (cex * cex + cey * cey + cez * cez) *
        (
          dez * ab_err +
          aez * bd_err +
          bez * da_err +
          (deztail * ab.data[3] + aeztail * bd.data[3] + beztail * da.data[3])
        )
      )
    ) +
    2.0 *
    (
      (bex * bextail + bey * beytail + bez * beztail) *
      (cez * da.data[3] + dez * ac.data[3] + aez * cd.data[3]) +
      (dex * dextail + dey * deytail + dez * deztail) *
      (aez * bc.data[3] - bez * ac.data[3] + cez * ab.data[3]) -
      (
        (aex * aextail + aey * aeytail + aez * aeztail) *
        (bez * cd.data[3] - cez * bd.data[3] + dez * bc.data[3]) +
        (cex * cextail + cey * ceytail + cez * ceztail) *
        (dez * ab.data[3] + aez * bd.data[3] + bez * da.data[3])
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

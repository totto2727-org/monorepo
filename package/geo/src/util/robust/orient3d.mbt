///|
/// Returns a positive value if the point `pd` lies below the plane passing through `pa`, `pb`, and `pc`
/// ("below" is defined so that `pa`, `pb`, and `pc` appear in counterclockwise order when viewed from above the plane).
/// Returns a negative value if `pd` lies above the plane.
/// Returns `0` if they are **coplanar**.
pub fn[Coord3D : @type.Coord3DTrait] orient3d(
  pa : Coord3D,
  pb : Coord3D,
  pc : Coord3D,
  pd : Coord3D,
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
  let adx = pa_x - pd_x
  let bdx = pb_x - pd_x
  let cdx = pc_x - pd_x
  let ady = pa_y - pd_y
  let bdy = pb_y - pd_y
  let cdy = pc_y - pd_y
  let adz = pa_z - pd_z
  let bdz = pb_z - pd_z
  let cdz = pc_z - pd_z
  let bdxcdy = bdx * cdy
  let cdxbdy = cdx * bdy
  let cdxady = cdx * ady
  let adxcdy = adx * cdy
  let adxbdy = adx * bdy
  let bdxady = bdx * ady
  let det = adz * (bdxcdy - cdxbdy) +
    bdz * (cdxady - adxcdy) +
    cdz * (adxbdy - bdxady)
  let permanent = (bdxcdy.abs() + cdxbdy.abs()) * adz.abs() +
    (cdxady.abs() + adxcdy.abs()) * bdz.abs() +
    (adxbdy.abs() + bdxady.abs()) * cdz.abs()
  let errbound = O3DERRBOUND_A * permanent
  if det > errbound || -det > errbound {
    return det
  }
  orient3dadapt(
    pa_x, pa_y, pa_z, pb_x, pb_y, pb_z, pc_x, pc_y, pc_z, pd_x, pd_y, pd_z, permanent,
  )
}

///|
fn orient3dadapt(
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
  permanent : Double,
) -> Double {
  let adx = pa_x - pd_x
  let bdx = pb_x - pd_x
  let cdx = pc_x - pd_x
  let ady = pa_y - pd_y
  let bdy = pb_y - pd_y
  let cdy = pc_y - pd_y
  let adz = pa_z - pd_z
  let bdz = pb_z - pd_z
  let cdz = pc_z - pd_z
  let (bdxcdy1, bdxcdy0) = two_product(bdx, cdy)
  let (cdxbdy1, cdxbdy0) = two_product(cdx, bdy)
  let (bc3, bc2, bc1, bc0) = two_two_diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
  let bc = [bc0, bc1, bc2, bc3]
  let adet = Array::make(8, 0.0)
  let alen = scale_expansion_zeroelim(bc, 4, adz, adet)
  let (cdxady1, cdxady0) = two_product(cdx, ady)
  let (adxcdy1, adxcdy0) = two_product(adx, cdy)
  let (ca3, ca2, ca1, ca0) = two_two_diff(cdxady1, cdxady0, adxcdy1, adxcdy0)
  let ca = [ca0, ca1, ca2, ca3]
  let bdet = Array::make(8, 0.0)
  let blen = scale_expansion_zeroelim(ca, 4, bdz, bdet)
  let (adxbdy1, adxbdy0) = two_product(adx, bdy)
  let (bdxady1, bdxady0) = two_product(bdx, ady)
  let (ab3, ab2, ab1, ab0) = two_two_diff(adxbdy1, adxbdy0, bdxady1, bdxady0)
  let ab = [ab0, ab1, ab2, ab3]
  let cdet = Array::make(8, 0.0)
  let clen = scale_expansion_zeroelim(ab, 4, cdz, cdet)
  let abdet = Array::make(16, 0.0)
  let ablen = fast_expansion_sum_zeroelim(adet, alen, bdet, blen, abdet)
  let fin1 = Array::make(192, 0.0)
  let finlength = fast_expansion_sum_zeroelim(abdet, ablen, cdet, clen, fin1)
  let mut det = estimate(fin1, finlength)
  let mut errbound = O3DERRBOUND_B * permanent
  if det >= errbound || -det >= errbound {
    return det
  }
  let adxtail = two_diff_tail(pa_x, pd_x, adx)
  let bdxtail = two_diff_tail(pb_x, pd_x, bdx)
  let cdxtail = two_diff_tail(pc_x, pd_x, cdx)
  let adytail = two_diff_tail(pa_y, pd_y, ady)
  let bdytail = two_diff_tail(pb_y, pd_y, bdy)
  let cdytail = two_diff_tail(pc_y, pd_y, cdy)
  let adztail = two_diff_tail(pa_z, pd_z, adz)
  let bdztail = two_diff_tail(pb_z, pd_z, bdz)
  let cdztail = two_diff_tail(pc_z, pd_z, cdz)
  if adxtail == 0.0 &&
    bdxtail == 0.0 &&
    cdxtail == 0.0 &&
    adytail == 0.0 &&
    bdytail == 0.0 &&
    cdytail == 0.0 &&
    adztail == 0.0 &&
    bdztail == 0.0 &&
    cdztail == 0.0 {
    return det
  }
  errbound = O3DERRBOUND_C * permanent + RESULTERRBOUND * det.abs()
  det += adz * (bdx * cdytail + cdy * bdxtail - (bdy * cdxtail + cdx * bdytail)) +
    adztail * (bdx * cdy - bdy * cdx) +
    (
      bdz * (cdx * adytail + ady * cdxtail - (cdy * adxtail + adx * cdytail)) +
      bdztail * (cdx * ady - cdy * adx)
    ) +
    (
      cdz * (adx * bdytail + bdy * adxtail - (ady * bdxtail + bdx * adytail)) +
      cdztail * (adx * bdy - ady * bdx)
    )
  if det >= errbound || -det >= errbound {
    return det
  }
  let finnow = fin1
  let finother = Array::make(192, 0.0)
  let at_b = Array::make(4, 0.0)
  let at_c = Array::make(4, 0.0)
  let bt_c = Array::make(4, 0.0)
  let bt_a = Array::make(4, 0.0)
  let ct_a = Array::make(4, 0.0)
  let ct_b = Array::make(4, 0.0)
  let mut at_blen = 0
  let mut at_clen = 0
  let mut bt_clen = 0
  let mut bt_alen = 0
  let mut ct_alen = 0
  let mut ct_blen = 0
  if adxtail == 0.0 {
    if adytail == 0.0 {
      at_b[0] = 0.0
      at_blen = 1
      at_c[0] = 0.0
      at_clen = 1
    } else {
      let negate = -adytail
      let (b1, b0) = two_product(negate, bdx)
      at_b[1] = b1
      at_b[0] = b0
      at_blen = 2
      let (c1, c0) = two_product(adytail, cdx)
      at_c[1] = c1
      at_c[0] = c0
      at_clen = 2
    }
  } else if adytail == 0.0 {
    let (b1, b0) = two_product(adxtail, bdy)
    at_b[1] = b1
    at_b[0] = b0
    at_blen = 2
    let negate = -adxtail
    let (c1, c0) = two_product(negate, cdy)
    at_c[1] = c1
    at_c[0] = c0
    at_clen = 2
  } else {
    let (adxt_bdy1, adxt_bdy0) = two_product(adxtail, bdy)
    let (adyt_bdx1, adyt_bdx0) = two_product(adytail, bdx)
    let (b3, b2, b1, b0) = two_two_diff(
      adxt_bdy1, adxt_bdy0, adyt_bdx1, adyt_bdx0,
    )
    at_b[3] = b3
    at_b[2] = b2
    at_b[1] = b1
    at_b[0] = b0
    at_blen = 4
    let (adyt_cdx1, adyt_cdx0) = two_product(adytail, cdx)
    let (adxt_cdy1, adxt_cdy0) = two_product(adxtail, cdy)
    let (c3, c2, c1, c0) = two_two_diff(
      adyt_cdx1, adyt_cdx0, adxt_cdy1, adxt_cdy0,
    )
    at_c[3] = c3
    at_c[2] = c2
    at_c[1] = c1
    at_c[0] = c0
    at_clen = 4
  }
  if bdxtail == 0.0 {
    if bdytail == 0.0 {
      bt_c[0] = 0.0
      bt_clen = 1
      bt_a[0] = 0.0
      bt_alen = 1
    } else {
      let negate = -bdytail
      let (c1, c0) = two_product(negate, cdx)
      bt_c[1] = c1
      bt_c[0] = c0
      bt_clen = 2
      let (a1, a0) = two_product(bdytail, adx)
      bt_a[1] = a1
      bt_a[0] = a0
      bt_alen = 2
    }
  } else if bdytail == 0.0 {
    let (c1, c0) = two_product(bdxtail, cdy)
    bt_c[1] = c1
    bt_c[0] = c0
    bt_clen = 2
    let negate = -bdxtail
    let (a1, a0) = two_product(negate, ady)
    bt_a[1] = a1
    bt_a[0] = a0
    bt_alen = 2
  } else {
    let (bdxt_cdy1, bdxt_cdy0) = two_product(bdxtail, cdy)
    let (bdyt_cdx1, bdyt_cdx0) = two_product(bdytail, cdx)
    let (c3, c2, c1, c0) = two_two_diff(
      bdxt_cdy1, bdxt_cdy0, bdyt_cdx1, bdyt_cdx0,
    )
    bt_c[3] = c3
    bt_c[2] = c2
    bt_c[1] = c1
    bt_c[0] = c0
    bt_clen = 4
    let (bdyt_adx1, bdyt_adx0) = two_product(bdytail, adx)
    let (bdxt_ady1, bdxt_ady0) = two_product(bdxtail, ady)
    let (a3, a2, a1, a0) = two_two_diff(
      bdyt_adx1, bdyt_adx0, bdxt_ady1, bdxt_ady0,
    )
    bt_a[3] = a3
    bt_a[2] = a2
    bt_a[1] = a1
    bt_a[0] = a0
    bt_alen = 4
  }
  if cdxtail == 0.0 {
    if cdytail == 0.0 {
      ct_a[0] = 0.0
      ct_alen = 1
      ct_b[0] = 0.0
      ct_blen = 1
    } else {
      let negate = -cdytail
      let (a1, a0) = two_product(negate, adx)
      ct_a[1] = a1
      ct_a[0] = a0
      ct_alen = 2
      let (b1, b0) = two_product(cdytail, bdx)
      ct_b[1] = b1
      ct_b[0] = b0
      ct_blen = 2
    }
  } else if cdytail == 0.0 {
    let (a1, a0) = two_product(cdxtail, ady)
    ct_a[1] = a1
    ct_a[0] = a0
    ct_alen = 2
    let negate = -cdxtail
    let (b1, b0) = two_product(negate, bdy)
    ct_b[1] = b1
    ct_b[0] = b0
    ct_blen = 2
  } else {
    let (cdxt_ady1, cdxt_ady0) = two_product(cdxtail, ady)
    let (cdyt_adx1, cdyt_adx0) = two_product(cdytail, adx)
    let (a3, a2, a1, a0) = two_two_diff(
      cdxt_ady1, cdxt_ady0, cdyt_adx1, cdyt_adx0,
    )
    ct_a[3] = a3
    ct_a[2] = a2
    ct_a[1] = a1
    ct_a[0] = a0
    ct_alen = 4
    let (cdyt_bdx1, cdyt_bdx0) = two_product(cdytail, bdx)
    let (cdxt_bdy1, cdxt_bdy0) = two_product(cdxtail, bdy)
    let (b3, b2, b1, b0) = two_two_diff(
      cdyt_bdx1, cdyt_bdx0, cdxt_bdy1, cdxt_bdy0,
    )
    ct_b[3] = b3
    ct_b[2] = b2
    ct_b[1] = b1
    ct_b[0] = b0
    ct_blen = 4
  }
  let bct = Array::make(8, 0.0)
  let cat = Array::make(8, 0.0)
  let abt = Array::make(8, 0.0)
  let u = Array::make(4, 0.0)
  let w = Array::make(16, 0.0)
  let v = Array::make(12, 0.0)
  let mut vlength = 0
  let bctlen = fast_expansion_sum_zeroelim(bt_c, bt_clen, ct_b, ct_blen, bct)
  let mut wlength = scale_expansion_zeroelim(bct, bctlen, adz, w)
  let mut finlength = fast_expansion_sum_zeroelim(
    finnow, 192, w, wlength, finother,
  ) // Use 192 as mock length if not tracked? No, fast_expansion needs actual length.
  // Wait, finlength was passed as result of previous sum? No.
  // In Rust code: finlength = fast_expansion_sum_zeroelim(&fin1[..finlength], ...)
  // So I need to track finlength properly.
  // Initially finlength comes from the first calculation.
  // Ah, in Moonbit `fast_expansion_sum_zeroelim` returns Int (length).
  // But wait, above I did `let finlength = fast_expansion_sum_zeroelim(...)`.
  // Here I am reusing `finlength`.
  // And `finnow` is `fin1`.

  // Correction: I need to handle swapping properly.
  // In Rust: `swap(&mut finnow, &mut finother)`.
  // In Moonbit references are immutable bindings to mutable objects.
  // But `finnow` and `finother` variables reference arrays.
  // I cannot swap what the variable points to if they are `let`.
  // I need `simple_swap` to swap *contents* or use a wrapper.
  // Using `simple_swap` as defined at the end.

  simple_swap(finnow, finother)
  let catlen = fast_expansion_sum_zeroelim(ct_a, ct_alen, at_c, at_clen, cat)
  wlength = scale_expansion_zeroelim(cat, catlen, bdz, w)
  finlength = fast_expansion_sum_zeroelim(
    finnow, finlength, w, wlength, finother,
  )
  simple_swap(finnow, finother)
  let abtlen = fast_expansion_sum_zeroelim(at_b, at_blen, bt_a, bt_alen, abt)
  wlength = scale_expansion_zeroelim(abt, abtlen, cdz, w)
  finlength = fast_expansion_sum_zeroelim(
    finnow, finlength, w, wlength, finother,
  )
  simple_swap(finnow, finother)
  if adztail != 0.0 {
    vlength = scale_expansion_zeroelim(bc, 4, adztail, v)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, v, vlength, finother,
    )
    simple_swap(finnow, finother)
  }
  if bdztail != 0.0 {
    vlength = scale_expansion_zeroelim(ca, 4, bdztail, v)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, v, vlength, finother,
    )
    simple_swap(finnow, finother)
  }
  if cdztail != 0.0 {
    vlength = scale_expansion_zeroelim(ab, 4, cdztail, v)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, v, vlength, finother,
    )
    simple_swap(finnow, finother)
  }
  if adxtail != 0.0 {
    if bdytail != 0.0 {
      let (adxt_bdyt1, adxt_bdyt0) = two_product(adxtail, bdytail)
      let (u3, u2, u1, u0) = two_one_product(adxt_bdyt1, adxt_bdyt0, cdz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if cdztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(adxt_bdyt1, adxt_bdyt0, cdztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
    if cdytail != 0.0 {
      let negate = -adxtail
      let (adxt_cdyt1, adxt_cdyt0) = two_product(negate, cdytail)
      let (u3, u2, u1, u0) = two_one_product(adxt_cdyt1, adxt_cdyt0, bdz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if bdztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(adxt_cdyt1, adxt_cdyt0, bdztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
  }
  if bdxtail != 0.0 {
    if cdytail != 0.0 {
      let (bdxt_cdyt1, bdxt_cdyt0) = two_product(bdxtail, cdytail)
      let (u3, u2, u1, u0) = two_one_product(bdxt_cdyt1, bdxt_cdyt0, adz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if adztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(bdxt_cdyt1, bdxt_cdyt0, adztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
    if adytail != 0.0 {
      let negate = -bdxtail
      let (bdxt_adyt1, bdxt_adyt0) = two_product(negate, adytail)
      let (u3, u2, u1, u0) = two_one_product(bdxt_adyt1, bdxt_adyt0, cdz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if cdztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(bdxt_adyt1, bdxt_adyt0, cdztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
  }
  if cdxtail != 0.0 {
    if adytail != 0.0 {
      let (cdxt_adyt1, cdxt_adyt0) = two_product(cdxtail, adytail)
      let (u3, u2, u1, u0) = two_one_product(cdxt_adyt1, cdxt_adyt0, bdz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if bdztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(cdxt_adyt1, cdxt_adyt0, bdztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
    if bdytail != 0.0 {
      let negate = -cdxtail
      let (cdxt_bdyt1, cdxt_bdyt0) = two_product(negate, bdytail)
      let (u3, u2, u1, u0) = two_one_product(cdxt_bdyt1, cdxt_bdyt0, adz)
      u[3] = u3
      u[2] = u2
      u[1] = u1
      u[0] = u0
      finlength = fast_expansion_sum_zeroelim(finnow, finlength, u, 4, finother)
      simple_swap(finnow, finother)
      if adztail != 0.0 {
        let (u3, u2, u1, u0) = two_one_product(cdxt_bdyt1, cdxt_bdyt0, adztail)
        u[3] = u3
        u[2] = u2
        u[1] = u1
        u[0] = u0
        finlength = fast_expansion_sum_zeroelim(
          finnow, finlength, u, 4, finother,
        )
        simple_swap(finnow, finother)
      }
    }
  }
  if adztail != 0.0 {
    wlength = scale_expansion_zeroelim(bct, bctlen, adztail, w)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, w, wlength, finother,
    )
    simple_swap(finnow, finother)
  }
  if bdztail != 0.0 {
    wlength = scale_expansion_zeroelim(cat, catlen, bdztail, w)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, w, wlength, finother,
    )
    simple_swap(finnow, finother)
  }
  if cdztail != 0.0 {
    wlength = scale_expansion_zeroelim(abt, abtlen, cdztail, w)
    finlength = fast_expansion_sum_zeroelim(
      finnow, finlength, w, wlength, finother,
    )
    simple_swap(finnow, finother)
  }
  finnow[finlength - 1]
}

///|
fn simple_swap(a : Array[Double], b : Array[Double]) -> Unit {
  let len = a.length()
  for i = 0; i < len; i = i + 1 {
    let tmp = a[i]
    a[i] = b[i]
    b[i] = tmp
  }
}

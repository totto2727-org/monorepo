// Ported from georust/robust
// https://github.com/georust/robust/blob/master/src/lib.rs (incircle)
//
// NOTE: This implementation provides only the **non-adaptive** fast path of
// Shewchuk's `incircle` predicate. For typical inputs that are not near the
// boundary of cocircularity it returns the same sign as the full predicate.
// Cases that fall through the error bound currently return the simple
// determinant value (which has the correct sign in well-separated cases but
// may misclassify near-cocircular inputs). The full adaptive version (~600
// lines) can be added later if Delaunay triangulation / Voronoi diagram
// algorithms come into scope (currently out of scope per the geo-mbt
// roadmap).

///|
/// Returns a positive value if `pd` lies **inside** the circle through
/// `pa`, `pb`, `pc` (with the points in CCW order). Negative if outside,
/// zero if cocircular.
pub fn incircle(
  pa : @type.Coord,
  pb : @type.Coord,
  pc : @type.Coord,
  pd : @type.Coord,
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
  // Adaptive path (truncated): return the determinant. This may misclassify
  // near-cocircular inputs; see the module docstring above.
  det
}

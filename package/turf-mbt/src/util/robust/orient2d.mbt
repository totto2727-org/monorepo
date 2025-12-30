///|
/// orient2d (CCW) 誤差境界 B
let ccw_err_bound_b : Double = (2.0 + 12.0 * epsilon) * epsilon

///|
/// orient2d (CCW) 誤差境界 C
let ccw_err_bound_c : Double = (9.0 + 64.0 * epsilon) * epsilon * epsilon

///|
/// orient2d の適応的精度計算（内部関数）
fn orient2d_adapt(
  pa : Coord,
  pb : Coord,
  pc : Coord,
  detsum : Double,
) -> Double {
  // 座標の差分計算
  let acx = pa.x - pc.x
  let bcx = pb.x - pc.x
  let acy = pa.y - pc.y
  let bcy = pb.y - pc.y

  // 行列式の部分積計算（誤差なし）
  let (detleft, detlefttail) = two_product(acx, bcy)
  let (detright, detrighttail) = two_product(acy, bcx)
  let (b3, b2, b1, b0) = two_two_diff(
    detleft, detlefttail, detright, detrighttail,
  )
  let b : FixedArray[Double] = [b0, b1, b2, b3]
  let det = estimate(b, 4)

  // 誤差境界のチェック
  let errbound = ccw_err_bound_b * detsum
  if det >= errbound || -det >= errbound {
    return det
  }
  let acxtail = two_diff_tail(pa.x, pc.x, acx)
  let bcxtail = two_diff_tail(pb.x, pc.x, bcx)
  let acytail = two_diff_tail(pa.y, pc.y, acy)
  let bcytail = two_diff_tail(pb.y, pc.y, bcy)
  if acxtail == 0.0 && acytail == 0.0 && bcxtail == 0.0 && bcytail == 0.0 {
    return det
  }
  let errbound_c = ccw_err_bound_c * detsum + result_err_bound * abs(det)
  let det = det +
    (acx * bcytail + bcy * acxtail) -
    (acy * bcxtail + bcx * acytail)
  if det >= errbound_c || -det >= errbound_c {
    return det
  }
  let (s1, s0) = two_product(acxtail, bcy)
  let (t1, t0) = two_product(acytail, bcx)
  let (u3, u2, u1, u0) = two_two_diff(s1, s0, t1, t0)
  let u : FixedArray[Double] = [u0, u1, u2, u3]
  let c1 : FixedArray[Double] = FixedArray::make(8, 0.0)
  let c1length = fast_expansion_sum_zeroelim(b, 4, u, 4, c1)
  let (s1_2, s0_2) = two_product(acx, bcytail)
  let (t1_2, t0_2) = two_product(acy, bcxtail)
  let (u3_2, u2_2, u1_2, u0_2) = two_two_diff(s1_2, s0_2, t1_2, t0_2)
  let u2 : FixedArray[Double] = [u0_2, u1_2, u2_2, u3_2]
  let c2 : FixedArray[Double] = FixedArray::make(12, 0.0)
  let c2length = fast_expansion_sum_zeroelim(c1, c1length, u2, 4, c2)
  let (s1_3, s0_3) = two_product(acxtail, bcytail)
  let (t1_3, t0_3) = two_product(acytail, bcxtail)
  let (u3_3, u2_3, u1_3, u0_3) = two_two_diff(s1_3, s0_3, t1_3, t0_3)
  let u3 : FixedArray[Double] = [u0_3, u1_3, u2_3, u3_3]
  let d : FixedArray[Double] = FixedArray::make(16, 0.0)
  let dlength = fast_expansion_sum_zeroelim(c2, c2length, u3, 4, d)
  d[dlength - 1]
}

///|
/// 2D向きテスト
///
/// 3点(pa, pb, pc)の向きを判定する。
/// - 正の値: 反時計回り (pcはpa→pbの左側)
/// - 負の値: 時計回り (pcはpa→pbの右側)
/// - 0: 3点が同一直線上
pub fn orient2d(
  pa : @geojson.Position,
  pb : @geojson.Position,
  pc : @geojson.Position,
) -> Double {
  let pa = to_coord(pa)
  let pb = to_coord(pb)
  let pc = to_coord(pc)

  // 近似計算
  let detleft = (pa.x - pc.x) * (pb.y - pc.y)
  let detright = (pa.y - pc.y) * (pb.x - pc.x)
  let det = detleft - detright
  let detsum = abs(detleft + detright)
  let theta : Double = 3.3306690621773722e-16
  let errbound = theta * detsum

  // 誤差範囲外なら結果を返す（高速パス）
  if det >= errbound || -det >= errbound {
    det
  } else {
    // 精度が必要な場合は適応的プロシージャを実行
    orient2d_adapt(pa, pb, pc, detsum)
  }
}

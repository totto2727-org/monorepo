///|
/// 抽象化なしの比較実験用関数
///
/// 2つのExpansionの和を計算する。ゼロ要素は除去される。
fn fast_expansion_sum_zeroelim(
  e : FixedArray[Double],
  e_length : Int,
  f : FixedArray[Double],
  f_length : Int,
  h : FixedArray[Double],
) -> Int {
  let mut e_now = e[0]
  let mut f_now = f[0]
  let mut e_index = 0
  let mut f_index = 0
  let mut q = 0.0
  if (f_now > e_now) == (f_now > -e_now) {
    q = e_now
    e_index = e_index + 1
  } else {
    q = f_now
    f_index = f_index + 1
  }
  let mut h_index = 0
  if e_index < e_length && f_index < f_length {
    e_now = e[e_index]
    f_now = f[f_index]
    let mut q_new = 0.0
    let mut hh = 0.0
    if (f_now > e_now) == (f_now > -e_now) {
      let r = fast_two_sum(e_now, q)
      q_new = r.0
      hh = r.1
      e_index = e_index + 1
    } else {
      let r = fast_two_sum(f_now, q)
      q_new = r.0
      hh = r.1
      f_index = f_index + 1
    }
    q = q_new
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
    while e_index < e_length && f_index < f_length {
      e_now = e[e_index]
      f_now = f[f_index]
      if (f_now > e_now) == (f_now > -e_now) {
        let r = two_sum(q, e_now)
        q_new = r.0
        hh = r.1
        e_index = e_index + 1
      } else {
        let r = two_sum(q, f_now)
        q_new = r.0
        hh = r.1
        f_index = f_index + 1
      }
      q = q_new
      if hh != 0.0 {
        h[h_index] = hh
        h_index = h_index + 1
      }
    }
  }
  while e_index < e_length {
    e_now = e[e_index]
    let r = two_sum(q, e_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    e_index = e_index + 1
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
  }
  while f_index < f_length {
    f_now = f[f_index]
    let r = two_sum(q, f_now)
    let q_new = r.0
    let hh = r.1
    q = q_new
    f_index = f_index + 1
    if hh != 0.0 {
      h[h_index] = hh
      h_index = h_index + 1
    }
  }
  if q != 0.0 || h_index == 0 {
    h[h_index] = q
    h_index = h_index + 1
  }
  h_index
}

///|
test (b : @bench.T) {
  let cases = Array::makei(100, _ => {
    let e1 = (@quickcheck.samples(5) : Array[Int])
      |> Array::map(x => 2.0.pow(x.to_double()))
      |> FixedArray::from_array
    e1.sort()
    let e1 = e1.rev()
    let e2 = (@quickcheck.samples(5) : Array[Int])
      |> Array::map(x => 2.0.pow(-x.to_double()))
      |> FixedArray::from_array
    e2.sort()
    let e2 = e2.rev()
    (e1, e2)
  })
  b.bench(name="use expansion type", fn() {
    for case in cases {
      let (e1, e2) = case
      let e1 = Expansion::from_fixed_array(e1)
      let e2 = Expansion::from_fixed_array(e2)
      let _ = e1.fast_expansion_sum_zeroelim(e2)

    }
  })
  b.bench(name="non-use expansion type", fn() {
    for case in cases {
      let h = FixedArray::make(10, 0.0)
      let (e1, e2) = case
      let _ = fast_expansion_sum_zeroelim(e1, 5, e2, 5, h)

    }
  })
}

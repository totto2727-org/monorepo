# sweep.mbt

Bentley-Ottmann simplified segment-intersection sweep, ported as a viable subset of georust/geo's `algorithm/sweep`. Sorts segments by their min-x and, for each segment, only checks subsequent segments whose min-x is at or before the current segment's max-x. The classical Bentley-Ottmann BST + priority queue are intentionally skipped — the simplified sweep runs in `O((n + m) log n)` where `m` is the count of x-overlapping pairs.

The monotone partition / `monotone_chain` building block is **not** included in this milestone (`TODO ms-19-monotone` in `sweep.mbt`); only the segment-intersection helpers needed by ms-20 (DE-9IM) and ms-21 (i_overlay segment intersection) are exposed.

## Public API

- `segment_intersections`
- `has_segment_intersection`

## Test

### `segment_intersections`

- Empty input yields an empty result.

```mbt check
///|
test "segment_intersections - empty input" {
  let coords = segment_intersections([])
  @test.assert_eq(coords.length(), 0)
}
```

- Two non-intersecting segments yield no intersections.

```mbt check
///|
test "segment_intersections - two disjoint segments" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (1.0, 0.0))
  let l2 = @type.Line::from_tuples((2.0, 1.0), (3.0, 1.0))
  let coords = segment_intersections([l1, l2])
  @test.assert_eq(coords.length(), 0)
}
```

- Two crossing segments meet at a single interior point.

```mbt check
///|
test "segment_intersections - two crossing segments meet at the center" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let l2 = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  let coords = segment_intersections([l1, l2])
  @test.assert_eq(coords.length(), 1)
  let c = coords[0]
  assert_true((c.x() - 5.0).abs() < TOLERANCE)
  assert_true((c.y() - 5.0).abs() < TOLERANCE)
}
```

- Three segments forming a triangle yield 3 intersections — one per shared corner. Each corner is reported once even though it is touched by two segments.

```mbt check
///|
test "segment_intersections - triangle yields 3 corner intersections" {
  let a = @type.Coord::Coord(0.0, 0.0)
  let b = @type.Coord::Coord(10.0, 0.0)
  let c = @type.Coord::Coord(5.0, 8.0)
  let ab = @type.Line::Line(a, b)
  let bc = @type.Line::Line(b, c)
  let ca = @type.Line::Line(c, a)
  let coords = segment_intersections([ab, bc, ca])
  @test.assert_eq(coords.length(), 3)
}
```

- Endpoint touches count as intersections, matching upstream's `LineIntersection::SinglePoint { is_proper: false }` path.

```mbt check
///|
test "segment_intersections - endpoint touch is reported" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let l2 = @type.Line::from_tuples((1.0, 1.0), (2.0, 0.0))
  let coords = segment_intersections([l1, l2])
  @test.assert_eq(coords.length(), 1)
  assert_true((coords[0].x() - 1.0).abs() < TOLERANCE)
  assert_true((coords[0].y() - 1.0).abs() < TOLERANCE)
}
```

- Collinear overlapping segments report the shared sub-segment endpoints, mirroring upstream's `LineIntersection::Collinear` coverage.

```mbt check
///|
test "segment_intersections - overlapping collinear segments" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (4.0, 0.0))
  let l2 = @type.Line::from_tuples((2.0, 0.0), (6.0, 0.0))
  let coords = segment_intersections([l1, l2])
  @test.assert_eq(coords.length(), 2)
  coords.sort_by(fn(a, b) {
    if a.x() < b.x() {
      -1
    } else if a.x() > b.x() {
      1
    } else {
      0
    }
  })
  assert_true((coords[0].x() - 2.0).abs() < TOLERANCE)
  assert_true(coords[0].y().abs() < TOLERANCE)
  assert_true((coords[1].x() - 4.0).abs() < TOLERANCE)
  assert_true(coords[1].y().abs() < TOLERANCE)
  assert_true(has_segment_intersection([l1, l2]))
}
```

- A 3 × 4 grid of horizontal × vertical segments produces 3 · 4 = 12 intersections.

```mbt check
///|
test "segment_intersections - 3x4 grid yields 12 intersections" {
  let segments : Array[@type.Line] = []
  // 3 horizontal segments at y = 1, 2, 3 spanning x ∈ [0, 5]
  let mut h = 1
  while h <= 3 {
    let y = h.to_double()
    segments.push(@type.Line::from_tuples((0.0, y), (5.0, y)))
    h = h + 1
  }
  // 4 vertical segments at x = 1, 2, 3, 4 spanning y ∈ [0, 4]
  let mut v = 1
  while v <= 4 {
    let x = v.to_double()
    segments.push(@type.Line::from_tuples((x, 0.0), (x, 4.0)))
    v = v + 1
  }
  let coords = segment_intersections(segments)
  @test.assert_eq(coords.length(), 12)
}
```

- A bow-tie — two diagonals of a unit square — has exactly one self-intersection at the centre.

```mbt check
///|
test "segment_intersections - bow-tie has 1 self-intersection" {
  let d1 = @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let d2 = @type.Line::from_tuples((1.0, 0.0), (0.0, 1.0))
  let coords = segment_intersections([d1, d2])
  @test.assert_eq(coords.length(), 1)
  let c = coords[0]
  assert_true((c.x() - 0.5).abs() < TOLERANCE)
  assert_true((c.y() - 0.5).abs() < TOLERANCE)
}
```

### `has_segment_intersection`

- Empty input has no intersections.

```mbt check
///|
test "has_segment_intersection - empty input" {
  @test.assert_eq(has_segment_intersection([]), false)
}
```

- Non-intersecting segments report false.

```mbt check
///|
test "has_segment_intersection - disjoint segments" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (1.0, 0.0))
  let l2 = @type.Line::from_tuples((2.0, 1.0), (3.0, 1.0))
  @test.assert_eq(has_segment_intersection([l1, l2]), false)
}
```

- Two crossing segments report true.

```mbt check
///|
test "has_segment_intersection - crossing segments" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let l2 = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  @test.assert_eq(has_segment_intersection([l1, l2]), true)
}
```

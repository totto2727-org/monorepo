# dbscan.mbt

Density-Based Spatial Clustering of Applications with Noise — ported
(in spirit) from georust/geo's
[`algorithm::dbscan`](https://github.com/georust/geo/blob/main/geo/src/algorithm/dbscan.rs).
DBSCAN groups points whose `eps`-neighbourhoods contain at least
`min_pts` neighbours (counting the point itself) and labels the rest as
noise. The R\*-tree (`@rtree`) backs every per-point neighbour query so
the sweep runs in `O(n log n)` for typical inputs instead of `O(n²)`.

The georust/geo crate also ships a separate `outlier_detection` module
with the Local Outlier Factor (LOF) algorithm; that is **not** ported
here. DBSCAN's noise label already answers "which points are
outliers", so the small `dbscan_outliers` helper exposes that subset
directly. Full LOF / ensemble outlier detection is a deferred
follow-up.

Cluster IDs are 1-based; `0` is reserved for noise so the returned
`Array[Int]` reads naturally without an `Option` wrapper.

## Public API

- `dbscan` — `(Array[Point], Double, Int) -> Array[Int]`
- `dbscan_outliers` — `(Array[Point], Double, Int) -> Array[Int]`

## Test

### `dbscan`

| Variable | State                            | Note                                  |  1  |  2  |  3  |  4  |  5  |
| :------- | :------------------------------- | :------------------------------------ | :-: | :-: | :-: | :-: | :-: |
| `points` | empty                            | empty result                          |  ✓  |     |     |     |     |
| `points` | 5 well-separated clusters of 3   | 5 cluster IDs, no noise               |     |  ✓  |     |     |     |
| `points` | 3 isolated points, `min_pts = 2` | every label is `0` (noise-only input) |     |     |  ✓  |     |     |
| `points` | 3 distinct points, `eps = 0`     | every label is `0`                    |     |     |     |  ✓  |     |
| `points` | 3 isolated points, `min_pts = 1` | every label is `> 0` (no noise)       |     |     |     |     |  ✓  |

- Empty input returns an empty result.

```mbt check
///|
test "dbscan - empty input" {
  let labels = dbscan([], 1.0, 2)
  @test.assert_eq(labels.length(), 0)
}
```

- Five well-separated clusters of three points each yield five distinct
  cluster IDs in seed order, with no point labelled noise.

```mbt check
///|
test "dbscan - 5 well-separated clusters" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(0.5, 0.0),
    @type.Point::Point(0.0, 0.5),
    @type.Point::Point(10.0, 0.0),
    @type.Point::Point(10.5, 0.0),
    @type.Point::Point(10.0, 0.5),
    @type.Point::Point(0.0, 10.0),
    @type.Point::Point(0.5, 10.0),
    @type.Point::Point(0.0, 10.5),
    @type.Point::Point(10.0, 10.0),
    @type.Point::Point(10.5, 10.0),
    @type.Point::Point(10.0, 10.5),
    @type.Point::Point(20.0, 20.0),
    @type.Point::Point(20.5, 20.0),
    @type.Point::Point(20.0, 20.5),
  ]
  let labels = dbscan(points, 1.0, 2)
  @test.assert_eq(labels.length(), 15)
  // Within each cluster the three points share a label.
  let mut k = 0
  while k < 15 {
    @test.assert_eq(labels[k], labels[k + 1])
    @test.assert_eq(labels[k + 1], labels[k + 2])
    k = k + 3
  }
  // Different clusters get different labels (cluster IDs assigned in
  // sweep order).
  assert_true(labels[0] != labels[3])
  assert_true(labels[3] != labels[6])
  assert_true(labels[6] != labels[9])
  assert_true(labels[9] != labels[12])
  // No noise; max label is exactly 5.
  let mut max_id = 0
  let mut has_noise = false
  for i = 0; i < 15; i = i + 1 {
    if labels[i] == 0 {
      has_noise = true
    }
    if labels[i] > max_id {
      max_id = labels[i]
    }
  }
  @test.assert_eq(has_noise, false)
  @test.assert_eq(max_id, 5)
}
```

- Three isolated points with `min_pts = 2` yields all-noise output.

```mbt check
///|
test "dbscan - noise only when neighbourhoods are empty" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(100.0, 0.0),
    @type.Point::Point(0.0, 100.0),
  ]
  let labels = dbscan(points, 1.0, 2)
  @test.assert_eq(labels[0], 0)
  @test.assert_eq(labels[1], 0)
  @test.assert_eq(labels[2], 0)
}
```

- `eps == 0` makes every neighbourhood a singleton, so with
  `min_pts = 2` every label is noise.

```mbt check
///|
test "dbscan - eps zero gives all noise" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(1.0, 0.0),
    @type.Point::Point(0.0, 1.0),
  ]
  let labels = dbscan(points, 0.0, 2)
  for i = 0; i < 3; i = i + 1 {
    @test.assert_eq(labels[i], 0)
  }
}
```

- `min_pts == 1` makes every point a core point, so every label is
  positive (no noise) — even when points are arbitrarily far apart.

```mbt check
///|
test "dbscan - min_pts=1 produces no noise" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(100.0, 0.0),
    @type.Point::Point(0.0, 100.0),
  ]
  let labels = dbscan(points, 1.0, 1)
  for i = 0; i < 3; i = i + 1 {
    assert_true(labels[i] > 0)
  }
}
```

### `dbscan_outliers`

| Variable | State                                  | Note                            |  1  |
| :------- | :------------------------------------- | :------------------------------ | :-: |
| `points` | dense triangle + 1 outlier (mp=3, e=1) | only the outlier index returned |  ✓  |

- Returns the indices labelled noise by `dbscan`.

```mbt check
///|
test "dbscan_outliers - extracts noise indices" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(0.5, 0.0),
    @type.Point::Point(0.0, 0.5),
    @type.Point::Point(100.0, 100.0),
  ]
  let outliers = dbscan_outliers(points, 1.0, 3)
  @test.assert_eq(outliers.length(), 1)
  @test.assert_eq(outliers[0], 3)
}
```

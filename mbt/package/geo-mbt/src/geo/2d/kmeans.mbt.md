# kmeans.mbt

K-means clustering — ported (in spirit) from georust/geo's [`algorithm::kmeans`](https://github.com/georust/geo/blob/main/geo/src/algorithm/kmeans/mod.rs).
This port ships the textbook Lloyd loop with "first k points" seeding; k-means++ initialisation, Hamerly triangle-inequality bound pruning, empty-cluster recovery, and the `max_radius` post-split are deferred follow-ups (see `TODO ms-31-kmeans++` in `kmeans.mbt`).

The function returns `Some((centroids, labels))` on success, where `centroids[j]` is the final coordinate of cluster `j` and `labels[i]` is the cluster assignment for `points[i]`. Invalid configurations (`k <= 0`, `k > points.length()`, or empty input) return `None`.

## Public API

- `kmeans` — `(Array[Point], Int, Int) -> (Array[Coord], Array[Int])?`

## Test

### `kmeans`

| Variable | State                           | Note                                       |  1  |  2  |  3  |  4  |  5  |  6  |
| :------- | :------------------------------ | :----------------------------------------- | :-: | :-: | :-: | :-: | :-: | :-: |
| `points` | empty                           | `None`                                     |  ✓  |     |     |     |     |     |
| `k`      | `0`                             | `None`                                     |     |  ✓  |     |     |     |     |
| `k`      | `> N`                           | `None`                                     |     |     |  ✓  |     |     |     |
| `points` | 3 well-separated clusters of 3  | each cluster shares a label, all distinct  |     |     |     |  ✓  |     |     |
| `points` | 4 points around (1, 1), `k = 1` | sole centroid is the exact arithmetic mean |     |     |     |     |  ✓  |     |
| `points` | 3 isolated points, `k = N`      | each point gets its own cluster            |     |     |     |     |     |  ✓  |

- Empty input returns `None` (since any positive `k` exceeds `points.length() == 0`).

```mbt check
///|
test "kmeans - empty input returns None" {
  let result = kmeans([], 1, 100)
  assert_true(result is None)
}
```

- `k = 0` is invalid.

```mbt check
///|
test "kmeans - k=0 returns None" {
  let points = [@type.Point::Point(0.0, 0.0), @type.Point::Point(1.0, 0.0)]
  let result = kmeans(points, 0, 100)
  assert_true(result is None)
}
```

- `k > N` is invalid.

```mbt check
///|
test "kmeans - k greater than N returns None" {
  let points = [@type.Point::Point(0.0, 0.0)]
  let result = kmeans(points, 5, 100)
  assert_true(result is None)
}
```

- Three well-separated clusters of three points each. The first three inputs are placed in distinct clusters (one per cluster) so the "first k points" seeding hits the correct local minimum, and Lloyd converges to that minimum within `max_iter`.

```mbt check
///|
test "kmeans - 3 well-separated clusters" {
  let points = [
    // Cluster seeds (one per natural cluster) so the first-k init
    // doesn't trap k-means in a local minimum.
    @type.Point::Point(0.0, 0.0), // seed for cluster A
    @type.Point::Point(10.0, 10.0), // seed for cluster B
    @type.Point::Point(20.0, 0.0), // seed for cluster C
    // Remaining members of cluster A.
    @type.Point::Point(1.0, 0.0),
    @type.Point::Point(0.0, 1.0),
    // Remaining members of cluster B.
    @type.Point::Point(11.0, 10.0),
    @type.Point::Point(10.0, 11.0),
    // Remaining members of cluster C.
    @type.Point::Point(21.0, 0.0),
    @type.Point::Point(20.0, 1.0),
  ]
  match kmeans(points, 3, 100) {
    Some((centroids, labels)) => {
      @test.assert_eq(centroids.length(), 3)
      @test.assert_eq(labels.length(), 9)
      // Cluster A: indices 0, 3, 4.
      @test.assert_eq(labels[0], labels[3])
      @test.assert_eq(labels[3], labels[4])
      // Cluster B: indices 1, 5, 6.
      @test.assert_eq(labels[1], labels[5])
      @test.assert_eq(labels[5], labels[6])
      // Cluster C: indices 2, 7, 8.
      @test.assert_eq(labels[2], labels[7])
      @test.assert_eq(labels[7], labels[8])
      // The three clusters get distinct labels.
      assert_true(labels[0] != labels[1])
      assert_true(labels[1] != labels[2])
      assert_true(labels[0] != labels[2])
    }
    None => assert_true(false)
  }
}
```

- `k = 1` puts every point in cluster `0`, and the sole centroid is the exact arithmetic mean of the input coordinates.

```mbt check
///|
test "kmeans - k=1 centroid is the mean" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(2.0, 0.0),
    @type.Point::Point(0.0, 2.0),
    @type.Point::Point(2.0, 2.0),
  ]
  match kmeans(points, 1, 100) {
    Some((centroids, labels)) => {
      @test.assert_eq(centroids.length(), 1)
      // Mean is (1.0, 1.0); ((0+2+0+2)/4, (0+0+2+2)/4) — exact in f64.
      @test.assert_eq(centroids[0].x(), 1.0)
      @test.assert_eq(centroids[0].y(), 1.0)
      for i = 0; i < 4; i = i + 1 {
        @test.assert_eq(labels[i], 0)
      }
    }
    None => assert_true(false)
  }
}
```

- `k == N` partitions each point into its own cluster, so every label is distinct.

```mbt check
///|
test "kmeans - k=N partitions each point alone" {
  let points = [
    @type.Point::Point(0.0, 0.0),
    @type.Point::Point(10.0, 0.0),
    @type.Point::Point(0.0, 10.0),
  ]
  match kmeans(points, 3, 100) {
    Some((centroids, labels)) => {
      @test.assert_eq(centroids.length(), 3)
      @test.assert_eq(labels.length(), 3)
      assert_true(labels[0] != labels[1])
      assert_true(labels[1] != labels[2])
      assert_true(labels[0] != labels[2])
    }
    None => assert_true(false)
  }
}
```

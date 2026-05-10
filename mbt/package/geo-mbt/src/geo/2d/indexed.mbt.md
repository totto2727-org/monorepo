# indexed.mbt

R*-tree-backed query helpers ported from georust/geo's
[`algorithm::indexed`](https://github.com/georust/geo/blob/main/geo/src/algorithm/indexed/).
Each function builds an index from a fixed input collection once and
returns a closure answering repeated spatial queries in roughly
`O(log n + k)` instead of brute-force `O(n)` per query.

The georust crate ships `PreparedGeometry` (R*-tree backed `Relate` /
`Contains` / `Intersects`) and `IntervalTreeMultiPolygon` (1-D interval
tree). The DE-9IM `Relate` machinery is out of scope for this port, so
this module instead exposes the simpler "build once, query many times"
pattern over the existing `contains` / `intersects` / `nearest`
predicates already provided by the package.

## Public API

- `indexed_contains_polygons` — `(Array[Polygon]) -> ((Coord) -> Bool)`
- `indexed_nearest_point` — `(Array[Point]) -> ((Coord) -> Point?)`
- `indexed_intersecting_polygons` — `(Array[Polygon]) -> ((Polygon) -> Array[Int])`

## Test

### `indexed_contains_polygons`

| Variable   | State                  | Note                                          |  1  |  2  |  3  |  4  |
| :--------- | :--------------------- | :-------------------------------------------- | :-: | :-: | :-: | :-: |
| `polygons` | empty                  | every query returns `false`                   |  ✓  |     |     |     |
| `polygons` | single polygon         | predicate equals `contains_polygon_coord`     |     |  ✓  |     |     |
| `polygons` | 10×10 grid (n = 100)   | predicate matches brute force on 100 queries  |     |     |  ✓  |     |
| `polygons` | 32×32 grid (n = 1024)  | predicate matches brute force on 200 queries  |     |     |     |  ✓  |

- Empty input: every query returns `false`.

```mbt check
///|
test "indexed_contains_polygons - empty input always returns false" {
  let pred = indexed_contains_polygons([])
  assert_true(!pred(@type.Coord(0.0, 0.0)))
  assert_true(!pred(@type.Coord(100.0, -50.0)))
}
```

- Single polygon: the indexed predicate equals `contains_polygon_coord`.

```mbt check
///|
test "indexed_contains_polygons - single polygon agrees with direct call" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let pred = indexed_contains_polygons([p])
  let probes = [
    @type.Coord(5.0, 5.0), // strictly inside
    @type.Coord(20.0, 20.0), // strictly outside
    @type.Coord(0.0, 0.0), // boundary corner
    @type.Coord(0.0, 5.0), // boundary edge
  ]
  for i = 0; i < probes.length(); i = i + 1 {
    @test.assert_eq(pred(probes[i]), contains_polygon_coord(p, probes[i]))
  }
}
```

- 10×10 grid (100 unit squares) — indexed result matches brute force on 100 deterministic query coords.

```mbt check
///|
test "indexed_contains_polygons - 10x10 grid matches brute force" {
  let polys = Array::makei(100, fn(idx) {
    let x = (idx / 10).to_double() * 2.0
    let y = (idx % 10).to_double() * 2.0
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (x, y),
        (x + 1.0, y),
        (x + 1.0, y + 1.0),
        (x, y + 1.0),
        (x, y),
      ]),
      [],
    )
  })
  let pred = indexed_contains_polygons(polys)
  for i = 0; i < 100; i = i + 1 {
    let q = @type.Coord(
      (i * 13 % 41).to_double() * 0.5,
      (i * 17 % 37).to_double() * 0.5,
    )
    let brute = polys.iter().any(fn(p) { contains_polygon_coord(p, q) })
    @test.assert_eq(pred(q), brute)
  }
}
```

- 1000-element stress (32×32 = 1024 unit squares) — verify correctness vs brute force on 200 query coords.

```mbt check
///|
test "indexed_contains_polygons - 32x32 stress matches brute force" {
  let polys = Array::makei(1024, fn(idx) {
    let x = (idx / 32).to_double() * 2.0
    let y = (idx % 32).to_double() * 2.0
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (x, y),
        (x + 1.0, y),
        (x + 1.0, y + 1.0),
        (x, y + 1.0),
        (x, y),
      ]),
      [],
    )
  })
  let pred = indexed_contains_polygons(polys)
  for i = 0; i < 200; i = i + 1 {
    let q = @type.Coord(
      (i * 23 % 131).to_double() * 0.5,
      (i * 31 % 127).to_double() * 0.5,
    )
    let brute = polys.iter().any(fn(p) { contains_polygon_coord(p, q) })
    @test.assert_eq(pred(q), brute)
  }
}
```

### `indexed_nearest_point`

| Variable | State                 | Note                                  |  1  |  2  |  3  |
| :------- | :-------------------- | :------------------------------------ | :-: | :-: | :-: |
| `points` | empty                 | every query returns `None`            |  ✓  |     |     |
| `points` | single point          | always returns that point             |     |  ✓  |     |
| `points` | 1000 distinct points  | matches brute-force nearest on 100 qs |     |     |  ✓  |

- Empty input: every query returns `None`.

```mbt check
///|
test "indexed_nearest_point - empty input returns None" {
  let pred = indexed_nearest_point([])
  assert_true(pred(@type.Coord(0.0, 0.0)) == None)
  assert_true(pred(@type.Coord(42.0, -7.5)) == None)
}
```

- Single point: nearest is always that point.

```mbt check
///|
test "indexed_nearest_point - single point" {
  let p = @type.Point::Point(3.0, 4.0)
  let pred = indexed_nearest_point([p])
  @test.assert_eq(pred(@type.Coord(0.0, 0.0)).unwrap(), p)
  @test.assert_eq(pred(@type.Coord(100.0, 100.0)).unwrap(), p)
}
```

- 1000 distinct points: indexed nearest equals brute-force nearest on 100 query coords.

```mbt check
///|
test "indexed_nearest_point - 1000 points stress matches brute force" {
  // 1000 distinct points scattered on a 50×20 grid (no coincident coords).
  let points = Array::makei(1000, fn(idx) {
    @type.Point::Point((idx / 20).to_double(), (idx % 20).to_double() * 1.5)
  })
  let pred = indexed_nearest_point(points)
  for i = 0; i < 100; i = i + 1 {
    let q = @type.Coord(
      (i * 7 % 53).to_double() * 0.9,
      (i * 11 % 31).to_double() * 1.0,
    )
    // Brute-force nearest by squared distance.
    let mut best_idx = 0
    let mut best_d = euclidean_distance_squared_coords(points[0].coord(), q)
    for j = 1; j < points.length(); j = j + 1 {
      let d = euclidean_distance_squared_coords(points[j].coord(), q)
      if d < best_d {
        best_d = d
        best_idx = j
      }
    }
    let got = pred(q).unwrap()
    let got_d = euclidean_distance_squared_coords(got.coord(), q)
    // Indexed answer must tie or match the brute-force best distance.
    // (Equal-distance ties may pick a different point.)
    @test.assert_eq(got_d, best_d)
    let _ = best_idx
  }
}
```

### `indexed_intersecting_polygons`

| Variable   | State                | Note                                          |  1  |  2  |  3  |  4  |
| :--------- | :------------------- | :-------------------------------------------- | :-: | :-: | :-: | :-: |
| `polygons` | empty                | every query returns `[]`                      |  ✓  |     |     |     |
| `polygons` | single polygon       | self-query yields `[0]`, disjoint yields `[]` |     |  ✓  |     |     |
| `polygons` | 10×10 grid (n = 100) | result set equals brute force                 |     |     |  ✓  |     |
| `polygons` | 32×32 stress (1024)  | result set equals brute force                 |     |     |     |  ✓  |

- Empty input: every query returns `[]`.

```mbt check
///|
test "indexed_intersecting_polygons - empty input returns []" {
  let pred = indexed_intersecting_polygons([])
  let q = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
      (0.0, 0.0),
    ]),
    [],
  )
  @test.assert_eq(pred(q).length(), 0)
}
```

- Single polygon: self-query yields `[0]`; disjoint query yields `[]`.

```mbt check
///|
test "indexed_intersecting_polygons - single polygon" {
  let p = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
      (0.0, 0.0),
    ]),
    [],
  )
  let pred = indexed_intersecting_polygons([p])
  let self_hits = pred(p)
  @test.assert_eq(self_hits.length(), 1)
  @test.assert_eq(self_hits[0], 0)
  let disjoint = @type.Polygon::Polygon(
    @type.LineString::from_tuples([
      (100.0, 100.0),
      (110.0, 100.0),
      (110.0, 110.0),
      (100.0, 110.0),
      (100.0, 100.0),
    ]),
    [],
  )
  @test.assert_eq(pred(disjoint).length(), 0)
}
```

- 10×10 grid: indexed result set equals the brute-force set for several query rectangles.

```mbt check
///|
test "indexed_intersecting_polygons - 10x10 grid matches brute force" {
  let polys = Array::makei(100, fn(idx) {
    let x = (idx / 10).to_double() * 2.0
    let y = (idx % 10).to_double() * 2.0
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (x, y),
        (x + 1.0, y),
        (x + 1.0, y + 1.0),
        (x, y + 1.0),
        (x, y),
      ]),
      [],
    )
  })
  let pred = indexed_intersecting_polygons(polys)
  // Probe with 5 query rectangles of varying sizes / positions.
  let queries = [
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (-1.0, -1.0),
        (3.0, -1.0),
        (3.0, 3.0),
        (-1.0, 3.0),
        (-1.0, -1.0),
      ]),
      [],
    ),
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (5.0, 5.0),
        (9.0, 5.0),
        (9.0, 9.0),
        (5.0, 9.0),
        (5.0, 5.0),
      ]),
      [],
    ),
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (100.0, 100.0),
        (110.0, 100.0),
        (110.0, 110.0),
        (100.0, 110.0),
        (100.0, 100.0),
      ]),
      [],
    ),
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (0.5, 0.5),
        (8.5, 0.5),
        (8.5, 8.5),
        (0.5, 8.5),
        (0.5, 0.5),
      ]),
      [],
    ),
  ]
  for k = 0; k < queries.length(); k = k + 1 {
    let q = queries[k]
    let indexed = pred(q)
    // Brute-force expected indices.
    let expected : Array[Int] = []
    for i = 0; i < polys.length(); i = i + 1 {
      if intersects_polygon_polygon(polys[i], q) {
        expected.push(i)
      }
    }
    @test.assert_eq(indexed.length(), expected.length())
    // Each expected index must appear in indexed; sets agree given equal
    // lengths and no duplicates from the rtree.
    for i = 0; i < expected.length(); i = i + 1 {
      let target = expected[i]
      assert_true(indexed.iter().any(fn(j) { j == target }))
    }
  }
}
```

- 32×32 stress (1024 polygons): indexed result set equals brute force for several queries.

```mbt check
///|
test "indexed_intersecting_polygons - 32x32 stress matches brute force" {
  let polys = Array::makei(1024, fn(idx) {
    let x = (idx / 32).to_double() * 2.0
    let y = (idx % 32).to_double() * 2.0
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (x, y),
        (x + 1.0, y),
        (x + 1.0, y + 1.0),
        (x, y + 1.0),
        (x, y),
      ]),
      [],
    )
  })
  let pred = indexed_intersecting_polygons(polys)
  let queries = [
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (10.0, 10.0),
        (20.0, 10.0),
        (20.0, 20.0),
        (10.0, 20.0),
        (10.0, 10.0),
      ]),
      [],
    ),
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (50.0, 50.0),
        (55.0, 50.0),
        (55.0, 55.0),
        (50.0, 55.0),
        (50.0, 50.0),
      ]),
      [],
    ),
    @type.Polygon::Polygon(
      @type.LineString::from_tuples([
        (-5.0, -5.0),
        (-1.0, -5.0),
        (-1.0, -1.0),
        (-5.0, -1.0),
        (-5.0, -5.0),
      ]),
      [],
    ),
  ]
  for k = 0; k < queries.length(); k = k + 1 {
    let q = queries[k]
    let indexed = pred(q)
    let expected : Array[Int] = []
    for i = 0; i < polys.length(); i = i + 1 {
      if intersects_polygon_polygon(polys[i], q) {
        expected.push(i)
      }
    }
    @test.assert_eq(indexed.length(), expected.length())
    for i = 0; i < expected.length(); i = i + 1 {
      let target = expected[i]
      assert_true(indexed.iter().any(fn(j) { j == target }))
    }
  }
}
```

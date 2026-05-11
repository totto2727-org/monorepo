// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/indexed/
//
// georust ships two indexed flavours: `PreparedGeometry` (R*-tree backed
// `Relate`/`Contains`/`Intersects`) and `IntervalTreeMultiPolygon` (1-D
// interval tree for point-in-multipolygon). The DE-9IM `Relate` machinery
// is out of scope for this port (per the package CLAUDE.md), so this
// module provides the simpler "build R*-tree of bboxes once, query many
// times" pattern that fits the existing `contains` / `intersects` /
// `nearest` predicates already implemented in the package. Each function
// takes a fixed input collection, builds an `RTree` once, and returns a
// closure answering subsequent queries in roughly `O(log n + k)` instead
// of brute-force `O(n)` per query.

///|
/// Pre-indexed contains predicate over a fixed set of polygons.
///
/// The R*-tree is built over the polygons' bounding rectangles. A query
/// coordinate is first narrowed to the candidate polygons whose bbox
/// covers it (`locate_at_point`), then verified against the precise
/// `contains_polygon_coord` test. Boundary coords return `false` per OGC
/// `Contains` semantics, mirroring the underlying predicate.
///
/// Polygons whose bounding rect is `None` (empty polygons) are skipped
/// at build time and never participate in queries.
pub fn indexed_contains_polygons(
  polygons : Array[@type.Polygon],
) -> (@type.Coord) -> Bool {
  let entries : Array[@rtree.Entry[Int]] = []
  for i = 0; i < polygons.length(); i = i + 1 {
    match bounding_rect_of_polygon(polygons[i]) {
      Some(rect) => entries.push(@rtree.Entry(rect, i))
      None => ()
    }
  }
  let tree = @rtree.RTree::bulk_load(entries)
  fn(coord) {
    tree
    .locate_at_point(coord)
    .iter()
    .any(fn(i) { contains_polygon_coord(polygons[i], coord) })
  }
}

///|
/// Pre-indexed nearest-neighbor lookup over a fixed set of points.
///
/// The R*-tree is built over degenerate point rects (`min == max ==
/// p.coord()`), so the tree's own `query_nearest` already returns the
/// correct answer without an extra precise pass. Empty input → closure
/// returns `None` for every query.
pub fn indexed_nearest_point(
  points : Array[@type.Point],
) -> (@type.Coord) -> @type.Point? {
  let entries = points.map(fn(p) {
    @rtree.Entry(@type.Rect::Rect(p.coord(), p.coord()), p)
  })
  let tree = @rtree.RTree::bulk_load(entries)
  fn(coord) { tree.query_nearest(coord) }
}

///|
/// Pre-indexed pairwise polygon-intersection lookup.
///
/// The R*-tree is built over the input polygons' bounding rectangles.
/// Given a query polygon, the closure narrows to candidates whose bbox
/// intersects the query bbox (`query_rect_intersection`), then keeps
/// only the indices that pass `intersects_polygon_polygon`. The result
/// is in the rtree's traversal order (no insertion-order guarantee).
///
/// Polygons whose bounding rect is `None` (empty polygons, both indexed
/// and query-side) never appear in the result. An empty input array
/// produces a closure that always returns `[]`.
pub fn indexed_intersecting_polygons(
  polygons : Array[@type.Polygon],
) -> (@type.Polygon) -> Array[Int] {
  let entries : Array[@rtree.Entry[Int]] = []
  for i = 0; i < polygons.length(); i = i + 1 {
    match bounding_rect_of_polygon(polygons[i]) {
      Some(rect) => entries.push(@rtree.Entry(rect, i))
      None => ()
    }
  }
  let tree = @rtree.RTree::bulk_load(entries)
  fn(query) {
    match bounding_rect_of_polygon(query) {
      None => []
      Some(query_rect) =>
        tree
        .query_rect_intersection(query_rect)
        .filter(fn(i) { intersects_polygon_polygon(polygons[i], query) })
    }
  }
}

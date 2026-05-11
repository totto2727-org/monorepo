// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/relate/
//
// TODO ms-20-followup: full geomgraph planar graph (which assigns side
// labels to every edge endpoint and intersection node, then synthesises
// the matrix from those labels) is deferred to a follow-up cycle. The
// current implementation uses direct case analysis for the common pairs:
//   Point x Point, Point x LineString, Point x Polygon,
//   LineString x LineString, LineString x Polygon, Polygon x Polygon.
// Triangle / Rect / Line are first reduced to Polygon / LineString.
// Multi-* and GeometryCollection fall through to a conservative
// pairwise predicate-based heuristic that fills in only the disjoint
// cells exactly. The OGC predicate masks (`is_contains`, `is_within`,
// ...) are computed exactly from the resulting 9 cells.

///|
/// The 9-element DE-9IM intersection matrix. Cells are stored row-major
/// in the order `[II, IB, IE, BI, BB, BE, EI, EB, EE]` where row =
/// position-in-A and col = position-in-B (I = Interior, B = Boundary,
/// E = Exterior). Each cell records the dimensionality of the
/// intersection of the two corresponding regions.
pub struct IntersectionMatrix {
  cells : Array[Dimensions]
}

///|
/// Construct a matrix with all cells set to `Empty`.
pub fn IntersectionMatrix::empty() -> IntersectionMatrix {
  IntersectionMatrix::{
    cells: [Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty],
  }
}

///|
fn pos_to_idx(p : CoordPos) -> Int {
  match p {
    Inside => 0
    OnBoundary => 1
    Outside => 2
  }
}

///|
/// Read the cell at `(row, col)` where `row` indexes A's position
/// (Interior / Boundary / Exterior) and `col` indexes B's position.
pub fn IntersectionMatrix::get(
  self : IntersectionMatrix,
  row : CoordPos,
  col : CoordPos,
) -> Dimensions {
  self.cells[pos_to_idx(row) * 3 + pos_to_idx(col)]
}

///|
fn IntersectionMatrix::set(
  self : IntersectionMatrix,
  row : CoordPos,
  col : CoordPos,
  dim : Dimensions,
) -> Unit {
  self.cells[pos_to_idx(row) * 3 + pos_to_idx(col)] = dim
}

///|
/// Updates the cell to the maximum of its current value and `dim`. Used
/// when multiple sources contribute to a single cell — only the
/// highest-rank dimensionality is retained.
fn IntersectionMatrix::set_at_least(
  self : IntersectionMatrix,
  row : CoordPos,
  col : CoordPos,
  dim : Dimensions,
) -> Unit {
  let cur = self.get(row, col)
  if dim.rank() > cur.rank() {
    self.set(row, col, dim)
  }
}

///|
/// Returns a transposed copy: cell `(row, col)` becomes cell
/// `(col, row)`. Mirrors the swap of A and B in `relate(a, b)` versus
/// `relate(b, a)`.
fn IntersectionMatrix::transpose(
  self : IntersectionMatrix,
) -> IntersectionMatrix {
  IntersectionMatrix::{
    cells: [
      self.cells[0],
      self.cells[3],
      self.cells[6],
      self.cells[1],
      self.cells[4],
      self.cells[7],
      self.cells[2],
      self.cells[5],
      self.cells[8],
    ],
  }
}

// MARK: predicates ----------------------------------------------------------

///|
/// Two geometries are disjoint iff none of `II`, `IB`, `BI`, `BB`
/// records any intersection. Matches DE-9IM `[FF*FF****]`.
pub fn IntersectionMatrix::is_disjoint(self : IntersectionMatrix) -> Bool {
  self.get(Inside, Inside) == Empty &&
  self.get(Inside, OnBoundary) == Empty &&
  self.get(OnBoundary, Inside) == Empty &&
  self.get(OnBoundary, OnBoundary) == Empty
}

///|
/// `is_intersects` is the negation of `is_disjoint`.
pub fn IntersectionMatrix::is_intersects(self : IntersectionMatrix) -> Bool {
  !self.is_disjoint()
}

///|
/// `a.contains(b)` per OGC: matches DE-9IM `[T*****FF*]`. Strict
/// interior inclusion — a point on `a`'s boundary does *not* count.
pub fn IntersectionMatrix::is_contains(self : IntersectionMatrix) -> Bool {
  self.get(Inside, Inside) != Empty &&
  self.get(Outside, Inside) == Empty &&
  self.get(Outside, OnBoundary) == Empty
}

///|
/// `a.within(b)` per OGC: matches DE-9IM `[T*F**F***]`. The transpose
/// of `is_contains`.
pub fn IntersectionMatrix::is_within(self : IntersectionMatrix) -> Bool {
  self.get(Inside, Inside) != Empty &&
  self.get(Inside, Outside) == Empty &&
  self.get(OnBoundary, Outside) == Empty
}

///|
/// `a.covers(b)`: every point of `b` lies in `a` (interior **or**
/// boundary). Matches one of `[T*****FF*]`, `[*T****FF*]`,
/// `[***T**FF*]`, `[****T*FF*]`.
pub fn IntersectionMatrix::is_covers(self : IntersectionMatrix) -> Bool {
  if self.get(Outside, Inside) != Empty ||
    self.get(Outside, OnBoundary) != Empty {
    return false
  }
  self.get(Inside, Inside) != Empty ||
  self.get(Inside, OnBoundary) != Empty ||
  self.get(OnBoundary, Inside) != Empty ||
  self.get(OnBoundary, OnBoundary) != Empty
}

///|
/// `a.is_covered_by(b)`: the transpose of `is_covers`. Matches one of
/// `[T*F**F***]`, `[*TF**F***]`, `[**FT*F***]`, `[**F*TF***]`.
pub fn IntersectionMatrix::is_covered_by(self : IntersectionMatrix) -> Bool {
  if self.get(Inside, Outside) != Empty ||
    self.get(OnBoundary, Outside) != Empty {
    return false
  }
  self.get(Inside, Inside) != Empty ||
  self.get(Inside, OnBoundary) != Empty ||
  self.get(OnBoundary, Inside) != Empty ||
  self.get(OnBoundary, OnBoundary) != Empty
}

///|
/// `a.equals(b)` topologically: matches DE-9IM `[T*F**FFF*]`. Both
/// geometries occupy exactly the same point set.
pub fn IntersectionMatrix::is_equals(self : IntersectionMatrix) -> Bool {
  self.get(Inside, Inside) != Empty &&
  self.get(Inside, Outside) == Empty &&
  self.get(Outside, Inside) == Empty &&
  self.get(Outside, OnBoundary) == Empty &&
  self.get(OnBoundary, Outside) == Empty
}

///|
/// `a.touches(b)`: at least one point in common, but interiors do not
/// intersect. Matches `[FT*******]`, `[F**T*****]`, or `[F***T****]`.
pub fn IntersectionMatrix::is_touches(self : IntersectionMatrix) -> Bool {
  if self.get(Inside, Inside) != Empty {
    return false
  }
  self.get(Inside, OnBoundary) != Empty ||
  self.get(OnBoundary, Inside) != Empty ||
  self.get(OnBoundary, OnBoundary) != Empty
}

///|
fn dim_max(a : Dimensions, b : Dimensions) -> Dimensions {
  if a.rank() >= b.rank() {
    a
  } else {
    b
  }
}

///|
fn dim_max3(a : Dimensions, b : Dimensions, c : Dimensions) -> Dimensions {
  dim_max(dim_max(a, b), c)
}

///|
/// `a.crosses(b)`: their intersection is non-empty but smaller-
/// dimensional than the maximum of the two operands. Two polygons
/// cannot cross. Two lines cross iff their intersection is a single
/// point.
pub fn IntersectionMatrix::is_crosses(self : IntersectionMatrix) -> Bool {
  let dims_a = dim_max3(
    self.get(Inside, Inside),
    self.get(Inside, OnBoundary),
    self.get(Inside, Outside),
  )
  let dims_b = dim_max3(
    self.get(Inside, Inside),
    self.get(OnBoundary, Inside),
    self.get(Outside, Inside),
  )
  let ra = dims_a.rank()
  let rb = dims_b.rank()
  if ra < rb {
    self.get(Inside, Inside) != Empty && self.get(Inside, Outside) != Empty
  } else if ra > rb {
    self.get(Inside, Inside) != Empty && self.get(Outside, Inside) != Empty
  } else if ra == 2 && rb == 2 {
    self.get(Inside, Inside) == ZeroDimensional
  } else {
    false
  }
}

///|
/// `a.overlaps(b)`: same dimension, interiors overlap, neither covers
/// the other. Matches `[1*T***T**]` (line / line) or `[T*T***T**]`
/// (point / point or polygon / polygon).
pub fn IntersectionMatrix::is_overlaps(self : IntersectionMatrix) -> Bool {
  let dims_a = dim_max3(
    self.get(Inside, Inside),
    self.get(Inside, OnBoundary),
    self.get(Inside, Outside),
  )
  let dims_b = dim_max3(
    self.get(Inside, Inside),
    self.get(OnBoundary, Inside),
    self.get(Outside, Inside),
  )
  match (dims_a, dims_b) {
    (OneDimensional, OneDimensional) =>
      self.get(Inside, Inside) == OneDimensional &&
      self.get(Inside, Outside) != Empty &&
      self.get(Outside, Inside) != Empty
    (ZeroDimensional, ZeroDimensional) | (TwoDimensional, TwoDimensional) =>
      self.get(Inside, Inside) != Empty &&
      self.get(Inside, Outside) != Empty &&
      self.get(Outside, Inside) != Empty
    _ => false
  }
}

// MARK: top-level relate -----------------------------------------------------

///|
/// Compute the DE-9IM intersection matrix for two geometries. Triangle,
/// Rect, and Line are reduced to Polygon / LineString first.
pub fn relate(a : @type.Geometry, b : @type.Geometry) -> IntersectionMatrix {
  match (a, b) {
    (@type.Geometry::Line(l), other) =>
      relate(line_to_line_string_geometry(l), other)
    (other, @type.Geometry::Line(l)) =>
      relate(other, line_to_line_string_geometry(l))
    (@type.Geometry::Triangle(t), other) =>
      relate(@type.Geometry::Polygon(t.to_polygon()), other)
    (other, @type.Geometry::Triangle(t)) =>
      relate(other, @type.Geometry::Polygon(t.to_polygon()))
    (@type.Geometry::Rect(r), other) =>
      relate(@type.Geometry::Polygon(r.to_polygon()), other)
    (other, @type.Geometry::Rect(r)) =>
      relate(other, @type.Geometry::Polygon(r.to_polygon()))
    (@type.Geometry::Point(p1), @type.Geometry::Point(p2)) =>
      relate_point_point(p1, p2)
    (@type.Geometry::Point(p), @type.Geometry::LineString(ls)) =>
      relate_point_line_string(p, ls)
    (@type.Geometry::LineString(ls), @type.Geometry::Point(p)) =>
      relate_point_line_string(p, ls).transpose()
    (@type.Geometry::Point(p), @type.Geometry::Polygon(poly)) =>
      relate_point_polygon(p, poly)
    (@type.Geometry::Polygon(poly), @type.Geometry::Point(p)) =>
      relate_point_polygon(p, poly).transpose()
    (@type.Geometry::LineString(la), @type.Geometry::LineString(lb)) =>
      relate_line_string_line_string(la, lb)
    (@type.Geometry::LineString(ls), @type.Geometry::Polygon(poly)) =>
      relate_line_string_polygon(ls, poly)
    (@type.Geometry::Polygon(poly), @type.Geometry::LineString(ls)) =>
      relate_line_string_polygon(ls, poly).transpose()
    (@type.Geometry::Polygon(p1), @type.Geometry::Polygon(p2)) =>
      relate_polygon_polygon(p1, p2)
    _ => relate_default(a, b)
  }
}

///|
fn line_to_line_string_geometry(l : @type.Line) -> @type.Geometry {
  @type.Geometry::LineString(@type.LineString::LineString([l.start(), l.end()]))
}

// MARK: convenience predicates -----------------------------------------------

///|
/// Convenience: derive `intersects` from the matrix.
pub fn relate_intersects(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_intersects()
}

///|
/// Convenience: derive `disjoint` from the matrix.
pub fn relate_disjoint(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_disjoint()
}

///|
/// Convenience: derive `contains` from the matrix.
pub fn relate_contains(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_contains()
}

///|
/// Convenience: derive `within` from the matrix.
pub fn relate_within(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_within()
}

///|
/// Convenience: derive `covers` from the matrix.
pub fn relate_covers(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_covers()
}

///|
/// Convenience: derive `touches` from the matrix.
pub fn relate_touches(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_touches()
}

///|
/// Convenience: derive `crosses` from the matrix.
pub fn relate_crosses(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_crosses()
}

///|
/// Convenience: derive `equals` from the matrix.
pub fn relate_equals(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_equals()
}

///|
/// Convenience: derive `overlaps` from the matrix.
pub fn relate_overlaps(a : @type.Geometry, b : @type.Geometry) -> Bool {
  relate(a, b).is_overlaps()
}

// MARK: helpers --------------------------------------------------------------

///|
/// Returns the dimensionality of the geometry's boundary. Mirrors
/// JTS / georust's `boundary_dimensions`. A Point has no boundary; a
/// LineString's boundary is its two endpoints (or empty if closed); a
/// Polygon's boundary is its rings.
fn boundary_dimension(g : @type.Geometry) -> Dimensions {
  match g {
    @type.Geometry::Point(_) => Empty
    @type.Geometry::MultiPoint(_) => Empty
    @type.Geometry::Line(l) =>
      if l.start() == l.end() {
        Empty
      } else {
        ZeroDimensional
      }
    @type.Geometry::LineString(ls) => {
      let coords = ls.coords()
      let n = coords.length()
      if n < 2 || coords[0] == coords[n - 1] {
        Empty
      } else {
        ZeroDimensional
      }
    }
    @type.Geometry::MultiLineString(mls) => {
      let mut open = false
      let lines = mls.line_strings()
      let mut k = 0
      while k < lines.length() {
        let coords = lines[k].coords()
        let nn = coords.length()
        if nn >= 2 && coords[0] != coords[nn - 1] {
          open = true
        }
        k = k + 1
      }
      if open {
        ZeroDimensional
      } else {
        Empty
      }
    }
    @type.Geometry::Polygon(_) => OneDimensional
    @type.Geometry::MultiPolygon(_) => OneDimensional
    @type.Geometry::Rect(_) => OneDimensional
    @type.Geometry::Triangle(_) => OneDimensional
    @type.Geometry::GeometryCollection(_) => Empty
  }
}

///|
/// Conservative fallback used by `relate` for combinations the direct
/// dispatch table doesn't handle (Multi-* / GeometryCollection). Fills
/// the disjoint cells from the per-geometry dimensions and otherwise
/// records only II / EE so the OGC predicates still produce meaningful
/// results.
fn relate_default(a : @type.Geometry, b : @type.Geometry) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  let dim_a = HasDimensions::dimensions(a)
  let dim_b = HasDimensions::dimensions(b)
  let bd_a = boundary_dimension(a)
  let bd_b = boundary_dimension(b)
  if !intersects_geometry(a, b) {
    m.set(Inside, Outside, dim_a)
    m.set(OnBoundary, Outside, bd_a)
    m.set(Outside, Inside, dim_b)
    m.set(Outside, OnBoundary, bd_b)
  } else {
    m.set(Inside, Inside, ZeroDimensional)
  }
  m
}

// MARK: pairwise relate functions --------------------------------------------

///|
fn relate_point_point(p1 : @type.Point, p2 : @type.Point) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  if p1 == p2 {
    m.set(Inside, Inside, ZeroDimensional)
  } else {
    m.set(Inside, Outside, ZeroDimensional)
    m.set(Outside, Inside, ZeroDimensional)
  }
  m
}

///|
fn relate_point_line_string(
  p : @type.Point,
  ls : @type.LineString,
) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return m
  }
  let is_open = coords[0] != coords[n - 1]
  // The LS interior is at least 1D; a single point can never cover it,
  // so EI is OneDimensional whenever the LS is non-degenerate.
  m.set(Outside, Inside, OneDimensional)
  if is_open {
    m.set(Outside, OnBoundary, ZeroDimensional)
  }
  match coord_position_for_line_string(p.coord(), ls) {
    Inside => m.set(Inside, Inside, ZeroDimensional)
    OnBoundary => m.set(Inside, OnBoundary, ZeroDimensional)
    Outside => m.set(Inside, Outside, ZeroDimensional)
  }
  m
}

///|
fn relate_point_polygon(
  p : @type.Point,
  poly : @type.Polygon,
) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  m.set(Outside, Inside, TwoDimensional)
  m.set(Outside, OnBoundary, OneDimensional)
  match coord_position_for_polygon(p.coord(), poly) {
    Inside => m.set(Inside, Inside, ZeroDimensional)
    OnBoundary => m.set(Inside, OnBoundary, ZeroDimensional)
    Outside => m.set(Inside, Outside, ZeroDimensional)
  }
  m
}

///|
fn coord_in_array(arr : Array[@type.Coord], c : @type.Coord) -> Bool {
  arr.iter().any(fn(x) { x == c })
}

///|
/// True if any vertex (or segment-midpoint) of `a` lies in the exterior
/// of `b`. Midpoint sampling catches the case where every vertex of a
/// segment is on `b`'s boundary but the segment itself runs through
/// `b`'s exterior (e.g. a segment drawn between two non-adjacent ring
/// vertices of `b`).
fn ls_extends_outside(a : @type.LineString, b : @type.LineString) -> Bool {
  let coords = a.coords()
  let mut i = 0
  while i < coords.length() {
    if coord_position_for_line_string(coords[i], b) == Outside {
      return true
    }
    i = i + 1
  }
  let segs = a.lines()
  let mut j = 0
  while j < segs.length() {
    let s = segs[j]
    let mid = @type.Coord::Coord(
      (s.start().x() + s.end().x()) / 2.0,
      (s.start().y() + s.end().y()) / 2.0,
    )
    if coord_position_for_line_string(mid, b) == Outside {
      return true
    }
    j = j + 1
  }
  false
}

///|
fn relate_line_string_line_string(
  a : @type.LineString,
  b : @type.LineString,
) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  let a_coords = a.coords()
  let b_coords = b.coords()
  let na = a_coords.length()
  let nb = b_coords.length()
  if na < 2 || nb < 2 {
    return m
  }
  let a_open = a_coords[0] != a_coords[na - 1]
  let b_open = b_coords[0] != b_coords[nb - 1]
  let a_endpoints : Array[@type.Coord] = if a_open {
    [a_coords[0], a_coords[na - 1]]
  } else {
    []
  }
  let b_endpoints : Array[@type.Coord] = if b_open {
    [b_coords[0], b_coords[nb - 1]]
  } else {
    []
  }
  let a_segs = a.lines()
  let b_segs = b.lines()
  let mut has_collinear = false
  let mut has_proper_crossing = false
  let mut a_int_b_bound = false
  let mut b_int_a_bound = false
  let mut i = 0
  while i < a_segs.length() {
    let mut j = 0
    while j < b_segs.length() {
      match line_intersection(a_segs[i], b_segs[j]) {
        Some(LineIntersection::Collinear(_)) => has_collinear = true
        Some(LineIntersection::SinglePoint(c, _)) => {
          let on_a_endpoint = coord_in_array(a_endpoints, c)
          let on_b_endpoint = coord_in_array(b_endpoints, c)
          if !on_a_endpoint && !on_b_endpoint {
            has_proper_crossing = true
          } else if on_a_endpoint && !on_b_endpoint {
            b_int_a_bound = true
          } else if !on_a_endpoint && on_b_endpoint {
            a_int_b_bound = true
          }
        }
        None => ()
      }
      j = j + 1
    }
    i = i + 1
  }
  if has_collinear {
    m.set(Inside, Inside, OneDimensional)
  } else if has_proper_crossing {
    m.set(Inside, Inside, ZeroDimensional)
  }
  if a_int_b_bound {
    m.set(Inside, OnBoundary, ZeroDimensional)
  }
  if b_int_a_bound {
    m.set(OnBoundary, Inside, ZeroDimensional)
  }
  // BB: do any endpoints coincide?
  let mut bb_match = false
  let mut k = 0
  while k < a_endpoints.length() {
    let mut h = 0
    while h < b_endpoints.length() {
      if a_endpoints[k] == b_endpoints[h] {
        bb_match = true
      }
      h = h + 1
    }
    k = k + 1
  }
  if bb_match {
    m.set(OnBoundary, OnBoundary, ZeroDimensional)
  }
  // BE / EB: endpoints in the other geometry's exterior
  let mut k2 = 0
  while k2 < a_endpoints.length() {
    if coord_position_for_line_string(a_endpoints[k2], b) == Outside {
      m.set(OnBoundary, Outside, ZeroDimensional)
    }
    k2 = k2 + 1
  }
  let mut k3 = 0
  while k3 < b_endpoints.length() {
    if coord_position_for_line_string(b_endpoints[k3], a) == Outside {
      m.set(Outside, OnBoundary, ZeroDimensional)
    }
    k3 = k3 + 1
  }
  // BI / IB: endpoints landing strictly in the other's interior
  let mut k4 = 0
  while k4 < a_endpoints.length() {
    if coord_position_for_line_string(a_endpoints[k4], b) == Inside {
      m.set_at_least(OnBoundary, Inside, ZeroDimensional)
    }
    k4 = k4 + 1
  }
  let mut k5 = 0
  while k5 < b_endpoints.length() {
    if coord_position_for_line_string(b_endpoints[k5], a) == Inside {
      m.set_at_least(Inside, OnBoundary, ZeroDimensional)
    }
    k5 = k5 + 1
  }
  // IE / EI: parts of each interior in the other's exterior
  if ls_extends_outside(a, b) {
    m.set(Inside, Outside, OneDimensional)
  }
  if ls_extends_outside(b, a) {
    m.set(Outside, Inside, OneDimensional)
  }
  m
}

///|
fn relate_line_string_polygon(
  ls : @type.LineString,
  poly : @type.Polygon,
) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  // Polygon is 2D and its boundary 1D — they always extend beyond a 1D LS.
  m.set(Outside, Inside, TwoDimensional)
  m.set(Outside, OnBoundary, OneDimensional)
  let coords = ls.coords()
  let n = coords.length()
  if n < 2 {
    return m
  }
  let ls_open = coords[0] != coords[n - 1]
  let endpoints : Array[@type.Coord] = if ls_open {
    [coords[0], coords[n - 1]]
  } else {
    []
  }
  // Sample each segment's midpoint to characterise the LS interior's
  // position relative to the polygon (Inside / OnBoundary / Outside).
  let segs = ls.lines()
  let mut i = 0
  while i < segs.length() {
    let s = segs[i]
    let mid = @type.Coord::Coord(
      (s.start().x() + s.end().x()) / 2.0,
      (s.start().y() + s.end().y()) / 2.0,
    )
    match coord_position_for_polygon(mid, poly) {
      Inside => m.set_at_least(Inside, Inside, OneDimensional)
      OnBoundary => m.set_at_least(Inside, OnBoundary, OneDimensional)
      Outside => m.set_at_least(Inside, Outside, OneDimensional)
    }
    i = i + 1
  }
  // Boundary cells: BI / BB / BE
  let mut k = 0
  while k < endpoints.length() {
    match coord_position_for_polygon(endpoints[k], poly) {
      Inside => m.set_at_least(OnBoundary, Inside, ZeroDimensional)
      OnBoundary => m.set_at_least(OnBoundary, OnBoundary, ZeroDimensional)
      Outside => m.set_at_least(OnBoundary, Outside, ZeroDimensional)
    }
    k = k + 1
  }
  m
}

///|
fn polygon_all_edges(p : @type.Polygon) -> Array[@type.Line] {
  let edges : Array[@type.Line] = []
  let ext = p.exterior().lines()
  let mut i = 0
  while i < ext.length() {
    edges.push(ext[i])
    i = i + 1
  }
  let interiors = p.interiors()
  let mut j = 0
  while j < interiors.length() {
    let ring = interiors[j].lines()
    let mut h = 0
    while h < ring.length() {
      edges.push(ring[h])
      h = h + 1
    }
    j = j + 1
  }
  edges
}

///|
/// `a` covers `b` iff every vertex of `b` lies in `a` (interior or
/// boundary) and no edge of `b` properly crosses an edge of `a`.
fn polygon_covers_polygon(a : @type.Polygon, b : @type.Polygon) -> Bool {
  let coords = b.exterior().coords()
  let mut i = 0
  while i < coords.length() {
    if coord_position_for_polygon(coords[i], a) == Outside {
      return false
    }
    i = i + 1
  }
  let a_edges = polygon_all_edges(a)
  let b_edges = polygon_all_edges(b)
  let mut j = 0
  while j < a_edges.length() {
    let mut k = 0
    while k < b_edges.length() {
      match line_intersection(a_edges[j], b_edges[k]) {
        Some(LineIntersection::SinglePoint(_, true)) => return false
        _ => ()
      }
      k = k + 1
    }
    j = j + 1
  }
  true
}

///|
/// `a` strictly contains `b` iff every vertex of `b` is strictly inside
/// `a` and no boundary edges touch.
fn strictly_contains_polygon_polygon(
  a : @type.Polygon,
  b : @type.Polygon,
) -> Bool {
  let coords = b.exterior().coords()
  let mut i = 0
  while i < coords.length() {
    if coord_position_for_polygon(coords[i], a) != Inside {
      return false
    }
    i = i + 1
  }
  let a_edges = polygon_all_edges(a)
  let b_edges = polygon_all_edges(b)
  let mut j = 0
  while j < a_edges.length() {
    let mut k = 0
    while k < b_edges.length() {
      if intersects_line_line(a_edges[j], b_edges[k]) {
        return false
      }
      k = k + 1
    }
    j = j + 1
  }
  true
}

///|
/// True when the two polygon interiors share more than just boundary —
/// detected via a vertex inside the other, or a proper edge crossing.
/// Touching-only configurations (shared edges or single corner touch)
/// return false.
fn polygon_interiors_overlap(a : @type.Polygon, b : @type.Polygon) -> Bool {
  let a_coords = a.exterior().coords()
  let mut i = 0
  while i < a_coords.length() {
    if coord_position_for_polygon(a_coords[i], b) == Inside {
      return true
    }
    i = i + 1
  }
  let b_coords = b.exterior().coords()
  let mut j = 0
  while j < b_coords.length() {
    if coord_position_for_polygon(b_coords[j], a) == Inside {
      return true
    }
    j = j + 1
  }
  let a_edges = polygon_all_edges(a)
  let b_edges = polygon_all_edges(b)
  let mut k = 0
  while k < a_edges.length() {
    let mut h = 0
    while h < b_edges.length() {
      match line_intersection(a_edges[k], b_edges[h]) {
        Some(LineIntersection::SinglePoint(_, true)) => return true
        _ => ()
      }
      h = h + 1
    }
    k = k + 1
  }
  false
}

///|
/// Dimensionality of the BB cell when two polygons touch: `OneDim` if
/// any edge pair is collinear (shared sub-segment), else `ZeroDim` if
/// a single-point touch exists, else `Empty`.
fn polygon_boundary_touch_dim(
  a : @type.Polygon,
  b : @type.Polygon,
) -> Dimensions {
  let a_edges = polygon_all_edges(a)
  let b_edges = polygon_all_edges(b)
  let mut found_collinear = false
  let mut found_point = false
  let mut k = 0
  while k < a_edges.length() {
    let mut h = 0
    while h < b_edges.length() {
      match line_intersection(a_edges[k], b_edges[h]) {
        Some(LineIntersection::Collinear(_)) => found_collinear = true
        Some(LineIntersection::SinglePoint(_, _)) => found_point = true
        None => ()
      }
      h = h + 1
    }
    k = k + 1
  }
  if found_collinear {
    OneDimensional
  } else if found_point {
    ZeroDimensional
  } else {
    Empty
  }
}

///|
fn relate_polygon_polygon(
  a : @type.Polygon,
  b : @type.Polygon,
) -> IntersectionMatrix {
  let m = IntersectionMatrix::empty()
  m.set(Outside, Outside, TwoDimensional)
  if !intersects_polygon_polygon(a, b) {
    m.set(Inside, Outside, TwoDimensional)
    m.set(OnBoundary, Outside, OneDimensional)
    m.set(Outside, Inside, TwoDimensional)
    m.set(Outside, OnBoundary, OneDimensional)
    return m
  }
  let a_covers = polygon_covers_polygon(a, b)
  let b_covers = polygon_covers_polygon(b, a)
  if a_covers && b_covers {
    // Topologically equal
    m.set(Inside, Inside, TwoDimensional)
    m.set(OnBoundary, OnBoundary, OneDimensional)
    return m
  }
  if a_covers {
    m.set(Inside, Inside, TwoDimensional)
    m.set(Inside, OnBoundary, OneDimensional)
    m.set(Inside, Outside, TwoDimensional)
    m.set(OnBoundary, Outside, OneDimensional)
    if !strictly_contains_polygon_polygon(a, b) {
      let bb = polygon_boundary_touch_dim(a, b)
      m.set(OnBoundary, OnBoundary, bb)
    }
    return m
  }
  if b_covers {
    return relate_polygon_polygon(b, a).transpose()
  }
  // Neither covers the other but they intersect.
  m.set(Inside, Outside, TwoDimensional)
  m.set(OnBoundary, Outside, OneDimensional)
  m.set(Outside, Inside, TwoDimensional)
  m.set(Outside, OnBoundary, OneDimensional)
  let bb = polygon_boundary_touch_dim(a, b)
  m.set(OnBoundary, OnBoundary, bb)
  if polygon_interiors_overlap(a, b) {
    m.set(Inside, Inside, TwoDimensional)
  }
  m
}

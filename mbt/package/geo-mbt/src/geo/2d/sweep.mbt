// Bentley-Ottmann simplified sweep — finds segment intersections by
// sorting segments by min-x and checking each against subsequent segments
// whose min-x is at or before the current segment's max-x. Mirrors
// georust/geo's `algorithm/sweep` (a single-event-vector simplification
// that runs in O((n + m) log n) where m is the number of x-overlapping
// pairs). The georust comments in `mod.rs` describe why this avoids the
// classical Bentley-Ottmann BST + priority queue.
//
// TODO ms-19-monotone: monotone partition + monotone_chain are deferred
// to a follow-up cycle. The current public API only exposes the segment
// intersection helpers needed by ms-20 (DE-9IM) and ms-21 (i_overlay).
//
// Ported (subset) from
// https://github.com/georust/geo/blob/main/geo/src/algorithm/sweep/

///|
/// A line segment annotated with the [min, max] range of its x extent.
/// Sorting by `inserted_x` lets the sweep walk segments left-to-right
/// regardless of the segment's original orientation.
priv struct SweepInterval {
  inserted_x : Double
  deleted_x : Double
  segment : @type.Line
}

///|
/// Comparator that orders intervals by their `inserted_x` (min-x). Ties
/// fall through as 0 — stable ordering is not required for correctness.
fn sweep_interval_cmp(a : SweepInterval, b : SweepInterval) -> Int {
  if a.inserted_x < b.inserted_x {
    -1
  } else if a.inserted_x > b.inserted_x {
    1
  } else {
    0
  }
}

///|
/// Wraps each segment in a `SweepInterval` (computing min/max x) and
/// sorts the result by `inserted_x` ascending.
fn build_sweep_intervals(segments : Array[@type.Line]) -> Array[SweepInterval] {
  let intervals : Array[SweepInterval] = []
  let mut k = 0
  while k < segments.length() {
    let s = segments[k]
    let sx = s.start().x()
    let ex = s.end().x()
    let (lo, hi) = if sx < ex { (sx, ex) } else { (ex, sx) }
    intervals.push(SweepInterval::{ inserted_x: lo, deleted_x: hi, segment: s })
    k = k + 1
  }
  intervals.sort_by(sweep_interval_cmp)
  intervals
}

///|
/// True if any coord in `arr` is within `TOLERANCE` of `c` on both axes.
fn coord_already_present(arr : Array[@type.Coord], c : @type.Coord) -> Bool {
  let mut k = 0
  while k < arr.length() {
    let existing = arr[k]
    if (existing.x() - c.x()).abs() < TOLERANCE &&
      (existing.y() - c.y()).abs() < TOLERANCE {
      return true
    }
    k = k + 1
  }
  false
}

///|
/// Append `c` to `arr` only when no near-duplicate is already present.
fn add_unique_coord(arr : Array[@type.Coord], c : @type.Coord) -> Unit {
  if !coord_already_present(arr, c) {
    arr.push(c)
  }
}

///|
/// Returns all intersection points among the given line segments. Each
/// intersection is reported once even if multiple segments share it
/// (deduplication uses the module-wide `TOLERANCE` on both axes).
///
/// Endpoint touches count as intersections (matching `line_intersection`,
/// where a shared endpoint produces `SinglePoint(c, proper=false)`).
///
/// For a collinear-overlapping pair, both endpoints of the shared
/// sub-segment are emitted (deduplicated against any other reported
/// intersections).
pub fn segment_intersections(
  segments : Array[@type.Line],
) -> Array[@type.Coord] {
  let intervals = build_sweep_intervals(segments)
  let result : Array[@type.Coord] = []
  let n = intervals.length()
  let mut i = 0
  while i < n {
    let cur = intervals[i]
    let mut j = i + 1
    while j < n && intervals[j].inserted_x <= cur.deleted_x {
      let other = intervals[j]
      match line_intersection(cur.segment, other.segment) {
        Some(LineIntersection::SinglePoint(c, _)) => add_unique_coord(result, c)
        Some(LineIntersection::Collinear(l)) => {
          add_unique_coord(result, l.start())
          add_unique_coord(result, l.end())
        }
        None => ()
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

///|
/// Returns true iff any segment in the input intersects another. Short
/// circuits on the first detected intersection (any flavour: single
/// point or collinear overlap).
pub fn has_segment_intersection(segments : Array[@type.Line]) -> Bool {
  let intervals = build_sweep_intervals(segments)
  let n = intervals.length()
  let mut i = 0
  while i < n {
    let cur = intervals[i]
    let mut j = i + 1
    while j < n && intervals[j].inserted_x <= cur.deleted_x {
      match line_intersection(cur.segment, intervals[j].segment) {
        Some(_) => return true
        None => ()
      }
      j = j + 1
    }
    i = i + 1
  }
  false
}

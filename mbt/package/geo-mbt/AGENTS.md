# @totto2727/geo-mbt

## Overview

`@totto2727/geo-mbt` is a MoonBit port of [georust/geo](https://georust.org/), focused on 2D planar geospatial primitives and algorithms.

## Scope

- 2D only (Z coordinate is out of scope)
- `Double` (`f64`) coordinates only — no generic `T: CoordNum`
- Planar Euclidean and geographic (spherical/ellipsoidal) algorithms. Haversine, Vincenty,
  and Rhumb metric spaces are available for distance/length/bearing/destination.
  Geodesic (Karney / geographiclib-rs) remains deferred.
- Boolean ops, triangulation, R-tree spatial index, DE-9IM relate, and
  Bentley-Ottmann sweep are available (Phase 2 complete).

## Project Structure

- `src/geo/2d/type/` — geometry primitives (Coord, Point, Line, LineString, Polygon, etc.)
- `src/geo/2d/` — algorithms (area, bounding rect, distance, contains, etc.)
- `src/robust/` — robust predicates (orient2d, incircle) ported from the [`robust`](https://github.com/georust/robust) crate

Each directory contains a `moon.pkg.json` listing dependencies, source files (`*.mbt`), blackbox tests (`*_test.mbt`), and whitebox tests (`*_wbtest.mbt`).

## Commands

MoonBit workspace-level commands live in `mbt/AGENTS.md`. This package keeps only `build` because `w:build` fans out to package build tasks.

- `vp run w:build` — includes this package's `moon build`

## Workflow

After making API changes, follow `mbt/AGENTS.md` to refresh interfaces and format code. Check `.mbti` diffs to verify expected API changes.

## Roadmap

See `docs/roadmap/geo-mbt/` for the multi-cycle porting plan (15 milestones).

## Source references

The following repositories are cloned to `~/proj/geo/` for offline reference during the port:

- `georust-geo/` — main monorepo (`geo`, `geo-types`, `geo-traits`, `geo-test-fixtures`, `jts-test-runner`)
- `robust/` — robust predicates (`orient2d`, `incircle`, etc.)
- `rstar/`, `earcutr/`, `i_overlay/`, `spade/`, `geographiclib-rs/`, `num-traits/` — for future reference

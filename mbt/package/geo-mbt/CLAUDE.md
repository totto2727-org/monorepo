# @totto2727/geo-mbt

## Overview

`@totto2727/geo-mbt` is a MoonBit port of [georust/geo](https://georust.org/), focused on 2D planar geospatial primitives and algorithms.

## Scope

- 2D only (Z coordinate is out of scope)
- `Double` (`f64`) coordinates only — no generic `T: CoordNum`
- Planar Euclidean algorithms only — geodesic / spherical / Vincenty / Rhumb are out of scope
- Boolean ops, triangulation, R-tree spatial index, DE-9IM relate, Bentley-Ottmann sweep are out of scope (deferred to future roadmaps)

## Project Structure

- `src/geo/2d/type/` — geometry primitives (Coord, Point, Line, LineString, Polygon, etc.)
- `src/geo/2d/` — algorithms (area, bounding rect, distance, contains, etc.)
- `src/robust/` — robust predicates (orient2d, incircle) ported from the [`robust`](https://github.com/georust/robust) crate

Each directory contains a `moon.pkg.json` listing dependencies, source files (`*.mbt`), blackbox tests (`*_test.mbt`), and whitebox tests (`*_wbtest.mbt`).

## Commands

`build` / `check` / `fix` / `test` are Vite+ tasks (see `vite.config.ts`). Run them from the repo root via `vp run --filter @totto2727/geo-mbt <task>` or `vp run -r <task>`.

- `vp run --filter @totto2727/geo-mbt build` — `moon build`
- `vp run --filter @totto2727/geo-mbt check` — `moon check`
- `vp run --filter @totto2727/geo-mbt fix` — `moon fmt`
- `vp run --filter @totto2727/geo-mbt test` — `moon test`
- `moon info` — Update generated interface files (`.mbti`)

## Workflow

After making changes, always run `moon info` then `vp run --filter @totto2727/geo-mbt fix` to refresh interfaces and format code. Check `.mbti` diffs to verify expected API changes.

## Roadmap

See `docs/roadmap/geo-mbt/` for the multi-cycle porting plan (15 milestones).

## Source references

The following repositories are cloned to `~/proj/geo/` for offline reference during the port:

- `georust-geo/` — main monorepo (`geo`, `geo-types`, `geo-traits`, `geo-test-fixtures`, `jts-test-runner`)
- `robust/` — robust predicates (`orient2d`, `incircle`, etc.)
- `rstar/`, `earcutr/`, `i_overlay/`, `spade/`, `geographiclib-rs/`, `num-traits/` — for future reference

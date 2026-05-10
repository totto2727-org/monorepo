# @totto2727/geo

## Overview

`@totto2727/geo` is a GeoJSON and geospatial processing library written in MoonBit.

## Specifications

- [RFC 7946: The GeoJSON Format](https://www.rfc-editor.org/rfc/rfc7946.txt)
- [GeoJSON Type Definitions (TypeScript)](https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/refs/heads/master/types/geojson/index.d.ts)

## Project Structure

- `src/geojson/` - GeoJSON type definitions and processing (Point, LineString, Polygon, Feature, etc.)
- `src/json_helper/` - JSON conversion utilities
- `src/type/` - Core type definitions
- `src/turf/` - Geospatial algorithms (Turf.js-like)
- `src/util/robust/` - Robust computation algorithms

Each directory contains a `moon.pkg.json` listing dependencies, source files (`*.mbt`), blackbox tests (`*_test.mbt`), and whitebox tests (`*_wbtest.mbt`).

## Commands

`build` / `check` / `fix` / `test` are Vite+ tasks (see `vite.config.ts`). Run them from the repo root via `vp run --filter @totto2727/geo <task>` or `vp run -r <task>`. Direct `moon` invocations are reserved for subcommands without a task wrapper.

- `vp run --filter @totto2727/geo build` - `moon build`
- `vp run --filter @totto2727/geo check` - `moon check`
- `vp run --filter @totto2727/geo fix` - `moon fmt`
- `vp run --filter @totto2727/geo test` - `moon test` (snapshot updates still need `moon test --update`)
- `moon info` - Update generated interface files (`.mbti`)
- `moon coverage analyze > uncovered.log` - Check test coverage

## Workflow

After making changes, always run `moon info` then `vp run --filter @totto2727/geo fix` to refresh interfaces and format code. Check `.mbti` diffs to verify expected API changes.

For MoonBit coding conventions, see @SKILL.md

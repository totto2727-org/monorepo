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

- `moon build` - Build
- `moon check` - Type check
- `moon fmt` - Format code
- `moon test` - Run tests (`--update` to update snapshots)
- `moon info` - Update generated interface files (`.mbti`)
- `moon coverage analyze > uncovered.log` - Check test coverage

## Workflow

After making changes, always run `moon info && moon fmt` to update interfaces and format code. Check `.mbti` diffs to verify expected API changes.

For MoonBit coding conventions, see @SKILL.md

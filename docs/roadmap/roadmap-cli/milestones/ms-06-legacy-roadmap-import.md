---
milestone_id: 'ms-06-legacy-roadmap-import'
roadmap_id: 'roadmap-cli'
---

# Milestone: Legacy roadmap import and normalization

## Purpose

Add first-class CLI support for repository documentation migrations where existing roadmap progress files must be normalized without direct YAML editing.

## Outcomes (qualitative)

- The CLI can import or normalize legacy `roadmap-progress.yaml` files into `progress.yaml`.
- The CLI can refresh generated header comments when plugin paths or schema-reference locations change.
- The CLI can bulk-rewrite selected roadmap progress files to the current schema version while preserving milestone data.

## Scope

- `js/app/roadmap` CLI commands and progress-file helpers.
- Existing roadmap directories under `docs/roadmap/<roadmap-id>/`.
- Migration/normalization operations that currently require manual file moves or repeated no-op updates.

## Out of scope

- Tactical workflow execution orchestration.
- Non-roadmap documents outside `docs/roadmap/**`.
- Changing milestone semantics beyond schema/format normalization.

## Milestone dependencies

(none)

## Notes / additional remarks

Created during the 2026-05 docs/plugin cleanup after observing that progress content can be rewritten through the CLI, but legacy filename import and bulk normalization still require external file operations.

---
milestone_id: 'ms-06-progress-normalization'
roadmap_id: 'roadmap-cli'
---

# Milestone: Progress file normalization

## Purpose

Add first-class CLI support for normalizing roadmap progress files without direct YAML editing.

## Outcomes (qualitative)

- The CLI can normalize roadmap progress files into the canonical `progress.yaml` format.
- The CLI can refresh generated header comments when plugin paths or schema-reference locations change.
- The CLI can bulk-rewrite selected roadmap progress files to the current schema version while preserving milestone data.

## Scope

- `js/app/roadmap` CLI commands and progress-file helpers.
- Existing roadmap directories under `docs/roadmap/<roadmap-id>/`.
- Normalization operations that would otherwise require manual file moves or repeated no-op updates.

## Out of scope

- Tactical workflow execution orchestration.
- Non-roadmap documents outside `docs/roadmap/**`.
- Changing milestone semantics beyond schema/format normalization.

## Milestone dependencies

(none)

## Notes / additional remarks

The roadmap CLI is the canonical path for schema comments, progress-file names, and bulk progress-file rewrites.

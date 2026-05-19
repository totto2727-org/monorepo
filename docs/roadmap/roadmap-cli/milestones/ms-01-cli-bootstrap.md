---
milestone_id: ms-01-cli-bootstrap
roadmap_id: roadmap-cli
---

# Milestone: CLI bootstrap with new subcommand

## Purpose

Stand up the `@totto2727/roadmap` package as a working CLI binary (`roadmap`) with a `new` subcommand that scaffolds `docs/roadmap/<id>/progress.yaml`.

## Outcomes (qualitative)

- `vp run build` produces `js/app/roadmap/dist/bin.mjs`
- `roadmap new <id> --title <title>` creates a valid `progress.yaml` with roadmap_id, title, status, created_at/updated_at, and empty milestones
- Duplicate roadmap-id is rejected with exit 1
- Progress file is schema-validated before writing (RoadmapProgress, kebab-case enforcement)

## Scope

- `js/app/roadmap/` package: bin.ts, cli/new.ts, lib/progress.ts, schema/progress.ts
- Effect CLI (unstable), js-yaml for YAML read/write
- `docs/roadmap/roadmap-cli/progress.yaml` for self-tracking

## Out of scope

- Milestone management (deferred to ms-02)
- Listing / status / read commands (deferred to ms-03)
- Schema evolution beyond the effect/RoadmapProgress types

## Milestone dependencies

(none)

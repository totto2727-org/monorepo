---
milestone_id: ms-02-milestone-new
roadmap_id: roadmap-cli
---

# Milestone: milestone new subcommand

## Purpose

Add `roadmap milestone new <roadmap-id> <milestone-id>` so milestones can be appended to an existing `progress.yaml` and a scaffolded `.md` file generated.

## Outcomes (qualitative)

- `roadmap milestone new` appends a milestone entry to `progress.yaml` and bumps `updated_at`
- Generates `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` from a template, with only `milestone_id` and `roadmap_id` in frontmatter (status is tracked exclusively in `progress.yaml`)
- Duplicate milestone-id and missing roadmap both exit 1
- `--title` flag defaults to milestone-id
- `--dir` flag is shared from the parent `milestone` command via `withSharedFlags`

## Scope

- `cli/milestone/new.ts`, `lib/milestone.ts`, `lib/milestone-template.md`
- Template loaded via tsdown's `.md` text loader, `md.d.ts` ambient module declaration
- Template variables: milestone_id, roadmap_id, title (timestamps and status intentionally omitted from frontmatter)

## Out of scope

- Listing milestones or reading status (deferred to ms-03)
- Milestone update / status transitions

## Milestone dependencies

- ms-01-cli-bootstrap: `progress.yaml` schema and `roadmap new` must exist first

## Notes

Positional argument ordering in effect CLI follows object-key insertion order. Keys are named `roadmapId` / `targetId` (alphabetically `r < t`) to avoid `sort-keys` lint interference.

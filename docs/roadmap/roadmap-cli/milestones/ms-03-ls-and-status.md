---
milestone_id: ms-03-ls-and-status
roadmap_id: roadmap-cli
---

# Milestone: ls and status commands

## Purpose

Add read-only commands for listing and inspecting roadmaps and milestones: `roadmap ls`, `roadmap status`, `roadmap milestone ls`, `roadmap milestone status`.

## Outcomes (qualitative)

- `roadmap ls` lists all roadmaps under `<dir>` with status, title, and milestone completion counts
- `roadmap status <roadmap-id>` shows a single roadmap's metadata plus milestone table
- `roadmap milestone ls <roadmap-id>` lists all milestones with their status and depends_on
- `roadmap milestone status <roadmap-id> <milestone-id>` shows full milestone detail
- `--dir` moved to root command (`cli/root.ts`) as a shared flag; subcommands consume it via `yield* rootCommand`
- `listRoadmaps(dir)` in `lib/progress.ts` skips hidden entries and non-directories (`.gitkeep` safe)

## Scope

- `cli/root.ts` (new) — root command with shared `--dir`
- `cli/ls.ts`, `cli/status.ts` (new)
- `cli/milestone/ls.ts`, `cli/milestone/status.ts` (new; split from single `cli/milestone.ts`)
- `lib/progress.ts` — `listRoadmaps` + `ProgressDirNotFoundError`
- `bin.ts` — registers `lsCommand`, `statusCommand`, `rootCommand`

## Out of scope

- JSON / machine-readable output
- Milestone status transitions or updates
- Pagination for large milestone lists

## Milestone dependencies

- ms-01-cli-bootstrap: schema and CLI infrastructure
- ms-02-milestone-new: milestone data must exist to list/status

---
confirmed: true
---

# ADR: c-plugin — Command Sync Strategy

## Context

Each subcommand modifies the lock file and manages symlinks. A clear strategy is needed to avoid duplication of symlink logic and ensure consistency.

## Decision

### Additive commands: lock file update then sync

The following commands update the lock file first, then delegate to `sync` for all symlink operations:

- `skill add` — Adds repository/skills to lock file, then runs sync
- `skill update` — Pulls latest and updates commit hash in lock file, then runs sync
- `skill target add` — Adds directory to `skillDirs` in lock file, then runs sync

This ensures all symlinks (`.agents/skills/` + all `skillDirs`) are always consistent with the lock file state.

### Removal commands: lock file update then targeted deletion

The following commands update the lock file first, then delete only the affected symlinks:

- `skill remove` — Removes skills from lock file, then deletes only those skill symlinks from all directories
- `skill target remove` — Removes directories from `skillDirs` in lock file, then deletes symlinks only from the removed directories

Sync is not run after removal. This avoids unnecessary git operations and is more efficient since the remaining state is already consistent.

### sync command

`skill sync` reads the lock file and reconciles all symlinks to match. It is the single source of truth for symlink state.

## Impact

- `service/sync.ts` is the shared sync logic used by additive commands
- Removal commands use `service/symlink.ts` directly for targeted deletion
- No command performs both sync and targeted deletion

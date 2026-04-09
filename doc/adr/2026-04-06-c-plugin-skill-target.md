---
confirmed: true
---

# ADR: c-plugin skill target — Additional Symlink Directories

## Context

Skills managed by c-plugin are symlinked into `.agents/skills/`. However, tools like Claude Code read skills from `.claude/skills/`. Users need a way to configure additional directories where symlinks are placed, so that skills are available to multiple tools simultaneously.

This is a global setting per lock file, not per-skill. Individual skill-level target configuration is intentionally excluded.

## Decision

### 1. Lock File Schema Change

Add a required `skillDirs` array at the top level of the lock file. This contains paths (relative to the lock file or absolute) where additional symlinks are created.

```json
{
  "version": 1,
  "skillDirs": [".claude/skills"],
  "repositories": [...]
}
```

The primary `.agents/skills/` directory is always used implicitly. `skillDirs` lists **additional** directories.

### 2. Subcommand Structure

```
c-plugin skill target add <path>
c-plugin skill target remove
```

- `target add <path>` — Adds a directory path to `skillDirs` and immediately creates symlinks for all currently enabled skills
- `target remove` — Shows `Prompt.multiSelect` of current `skillDirs` entries, removes selected entries and their symlinks

Both inherit the `-g` flag from the parent `skill` command.

### 3. Symlink Behavior

On every `skill add`, `skill sync`, `skill update`, and `skill remove`, symlinks are managed in:

1. `.agents/skills/` (always, implicit)
2. Each directory listed in `skillDirs`

Symlinks in additional directories point to the same cache path as `.agents/skills/` symlinks.

### 4. Implementation

- `src/cli/skill/target/add.ts` — Add target directory
- `src/cli/skill/target/remove.ts` — Remove target directories
- Update `src/schema/lock-file.ts` — Add `skillDirs` field
- Update `src/service/symlink.ts` — Accept multiple target directories
- Update all CLI commands (add, sync, update, remove) — Pass `skillDirs` to symlink operations

## Impact

- **Lock file schema**: New required `skillDirs` field (breaking change for existing lock files — empty array `[]` is the default)
- **Symlink service**: Now operates on multiple directories
- **All CLI commands**: Updated to propagate `skillDirs`

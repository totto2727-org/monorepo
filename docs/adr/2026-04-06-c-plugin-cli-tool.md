---
confirmed: true
---

# ADR: c-plugin — CLI to Make Claude Code Plugin Resources Available for Other Tools

## Context

Claude Code Plugin repositories are becoming a popular way to distribute skills, but using these skills in other AI tools (Cursor, Windsurf, etc.) requires manual git cloning, file copying, and symlink creation.

Claude Code itself can install plugins directly, but symlink-based placement is needed for environments where plugins cannot be installed.

Vercel's skills CLI is difficult to use, so we create a dedicated CLI tool specialized for the Claude Code Plugin format, published as an npm package.

Currently only skill management is in scope, but the structure should allow future extension to hooks, MCP, agents, and other resources.

## Decision

### 1. Project Setup

- Path: `js/app/c-plugin`
- Node.js project (npm publishable, package name: `c-plugin`)
- Build: vite-plus (`vp build`)

### 2. Tech Stack

| Concern           | Choice                                        | Rationale                                                           |
| ----------------- | --------------------------------------------- | ------------------------------------------------------------------- |
| CLI framework     | `effect/unstable/cli`                         | CLI is bundled in Effect v4. No separate package needed             |
| Interactive UI    | `effect/unstable/cli` `Prompt.multiSelect`    | Built-in checkbox UI                                                |
| Runtime           | `@effect/platform-node`                       | Standard Effect Node.js platform layer                              |
| Schema validation | `effect` (Schema)                             | Aligns with existing monorepo patterns                              |
| Git operations    | `@effect/platform` Command API spawning `git` | No external library needed. git is a reasonable system prerequisite |
| Terminal output   | `ansis`                                       | Zero-dependency, fast                                               |

### 3. Subcommand Structure

```
c-plugin skill add <repo> [-g]
c-plugin skill sync [-g] [-r]
c-plugin skill update [-g] [-r]
c-plugin skill remove [-g]
```

Hierarchical structure allowing future addition of `c-plugin hook ...`, `c-plugin mcp ...`, etc.

Nested via Effect v4 CLI `Command.withSubcommands`:

```typescript
const skill = Command.make('skill').pipe(Command.withSubcommands([addCmd, syncCmd, updateCmd, removeCmd]))
const app = Command.make('c-plugin').pipe(Command.withSubcommands([skill]))
```

### 4. Project Directory Structure

```
js/app/c-plugin/
  package.json
  tsconfig.json
  vite.config.ts
  src/
    bin.ts                  # Entry point (Command.run)
    cli/
      skill/
        add.ts
        sync.ts
        update.ts
        remove.ts
    schema/
      lock-file.ts          # Effect Schema for lock file
      marketplace.ts        # Effect Schema for marketplace.json
    service/
      git.ts                # Git operations (clone, pull, rev-parse)
      lock-file.ts          # Lock file read/write
      cache.ts              # Cache directory management
      symlink.ts            # Symlink creation/removal
      skill-resolver.ts     # Resolve marketplace > plugin > skill hierarchy
    lib/
      paths.ts              # Path resolution (project vs global)
```

### 5. Lock File Format

Locations:

- Project: `.agents/skills-lock.json`
- Global: `~/.agents/skills-lock.json`

```json
{
  "version": 1,
  "repositories": [
    {
      "source": "totto2727-dotfiles/agents",
      "sourceType": "github",
      "commitHash": "abc123def456...",
      "plugins": [
        {
          "name": "totto2727",
          "path": "plugins/totto2727",
          "enabledSkills": ["exocortex", "git-workflow"]
        },
        {
          "name": "moonbit",
          "path": "plugins/moonbit",
          "enabledSkills": ["moonbit-docs"]
        }
      ]
    }
  ]
}
```

### 6. marketplace.json Schema

Located at `.claude-plugin/marketplace.json` in the repository root.

```json
{
  "name": "totto2727-marketplace",
  "plugins": [
    {
      "name": "totto2727",
      "source": "./plugins/totto2727"
    }
  ]
}
```

Initial release supports only relative paths within the repository. Each plugin is expected to have `<source>/skills/*/SKILL.md`.

### 7. Cache and Symlinks

```
.agents/
  skills-lock.json              # git tracked
  .cache/                       # gitignored
    <owner>/<repo>/             # git clone
  skills/                       # gitignored (symlinks only)
    exocortex -> ../.cache/<owner>/<repo>/plugins/<plugin>/skills/exocortex
```

- Independent cache per `.agents/` directory (allows version separation between global and project)
- Optional symlinks to `.claude/skills/` for environments without plugin support

### 8. Subcommand Details

#### `skill add <repo> [-g]`

1. Parse `owner/repo`, clone to `.agents/.cache/`
2. Parse `.claude-plugin/marketplace.json`
3. Enumerate skills from each plugin
4. Select skills via `Prompt.multiSelect` (hierarchy: repo > plugin > skill)
5. Update lock file (`commitHash` = `git rev-parse HEAD`)
6. Create symlinks in `.agents/skills/`

#### `skill sync [-g] [-r]`

1. Read lock file (`-g`: global, `-r`: recursive search upward)
2. Clone if not cached, otherwise `git checkout <commitHash>`
3. Auto-remove deleted skills from lock file and symlinks
4. Synchronize symlinks

#### `skill update [-g] [-r]`

1. `git pull` cached repositories to latest
2. Update `commitHash`
3. Detect deleted skills, auto-remove with warning
4. Re-synchronize symlinks

#### `skill remove [-g]`

1. Retrieve list of currently enabled skills from lock file
2. Select removal targets via `Prompt.multiSelect`
3. Update lock file and symlinks
4. Remove plugin entry if all its skills are deleted
5. Remove repository entry and cache if all its plugins are deleted

### 9. Flag Scope Summary

| Flag   | add            | sync                    | update                  | remove         |
| ------ | -------------- | ----------------------- | ----------------------- | -------------- |
| (none) | CWD `.agents/` | CWD `.agents/`          | CWD `.agents/`          | CWD `.agents/` |
| `-g`   | `~/.agents/`   | `~/.agents/`            | `~/.agents/`            | `~/.agents/`   |
| `-r`   | —              | Recursive upward search | Recursive upward search | —              |

### 10. .gitignore Management

The tool auto-appends to `.gitignore` if not already present:

```
.agents/.cache/
.agents/skills/
```

### 11. Error Handling

Using Effect `Data.TaggedError`:

- `GitCloneError` — Clone failure
- `GitNotInstalledError` — git not installed (checked at startup)
- `MarketplaceParseError` — marketplace.json schema validation error
- `LockFileCorruptError` — Lock file corruption
- `SkillNotFoundError` — Warning + auto-removal during sync/update

## Impact

- **New package**: `js/app/c-plugin/`
- **pnpm-workspace.yaml**: Catalog additions needed for `@effect/platform-node`, etc.
- **npm**: Published as `c-plugin` package

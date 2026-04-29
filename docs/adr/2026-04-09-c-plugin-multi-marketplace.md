---
confirmed: true
---

# ADR: c-plugin — Multi-Marketplace Input Support

## Context

Claude Code, Cursor, and Codex have converged on a nearly identical plugin/skill architecture. All three use `skills/*/SKILL.md` for skill definitions. The differences lie solely in:

1. The plugin config directory name
2. The marketplace manifest file location
3. The marketplace.json entry format (Codex differs)

### Tool Comparison

|                   | Claude Code                           | Cursor                                | Codex                                |
| ----------------- | ------------------------------------- | ------------------------------------- | ------------------------------------ |
| Plugin config dir | `.claude-plugin/`                     | `.cursor-plugin/`                     | `.codex-plugin/`                     |
| Marketplace file  | `.claude-plugin/marketplace.json`     | `.cursor-plugin/marketplace.json`     | `.agents/plugins/marketplace.json`   |
| Plugin manifest   | `<plugin>/.claude-plugin/plugin.json` | `<plugin>/.cursor-plugin/plugin.json` | `<plugin>/.codex-plugin/plugin.json` |
| Skill dir         | `<plugin>/skills/`                    | `<plugin>/skills/`                    | `<plugin>/skills/`                   |
| Skill file        | `SKILL.md`                            | `SKILL.md`                            | `SKILL.md`                           |

Note: Cursor also has `rules/*.mdc` but these are a distinct component type, not skills.

### Marketplace Entry Format Differences

Claude Code and Cursor share the same format:

```json
{
  "name": "example-marketplace",
  "plugins": [{ "name": "my-plugin", "source": "my-plugin", "description": "..." }]
}
```

Codex uses an object for `source` and adds `policy`/`category`:

```json
{
  "name": "example-marketplace",
  "plugins": [
    {
      "name": "my-plugin",
      "source": { "source": "local", "path": "./plugins/my-plugin" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
```

## Decision

### 1. Marketplace Kind

Define a `MarketplaceKind` type:

```typescript
type MarketplaceKind = 'claude' | 'cursor' | 'codex'
```

A configuration module maps each kind to its paths:

```typescript
const kindConfig = {
  claude: {
    configDir: '.claude-plugin',
    marketplacePath: '.claude-plugin/marketplace.json',
  },
  cursor: {
    configDir: '.cursor-plugin',
    marketplacePath: '.cursor-plugin/marketplace.json',
  },
  codex: {
    configDir: '.codex-plugin',
    marketplacePath: '.agents/plugins/marketplace.json',
  },
}
```

Skills are always resolved from `<plugin>/skills/` regardless of kind.

### 2. Normalized Marketplace Schema

The skill resolver normalizes all marketplace formats into a common internal representation. This means:

- For Claude/Cursor: `source` (string) is used as-is as the plugin relative path
- For Codex: `source.path` (string) is extracted, stripping the leading `./` prefix if present

After normalization, all marketplace entries look the same internally.

### 3. Lock File Schema Change

Add `marketplaceKind` to `RepositoryEntry`:

```json
{
  "version": 1,
  "skillDirs": [],
  "repositories": [
    {
      "source": "owner/repo",
      "sourceType": "github",
      "commitHash": "abc123...",
      "marketplaceKind": "claude",
      "plugins": [...]
    }
  ]
}
```

Default: `"claude"` (for backward compatibility with existing lock files).

### 4. Consumer: skill add

When running `c-plugin skill add <repo>`:

1. Clone the repository
2. Detect available marketplace kinds by checking which marketplace files exist
3. If multiple kinds are available, prompt the user to select one via `Prompt.select`
4. If only one kind is available, use it automatically
5. Parse the selected marketplace file (normalizing format differences)
6. Store the selected `marketplaceKind` in the lock file repository entry
7. Update lock file, then run sync

### 5. Consumer: skill sync / update

When syncing or updating, the stored `marketplaceKind` in the lock file determines which marketplace file to read from the cached repository. No re-detection is needed.

### 6. Author Tool: dev marketplace sync

```
c-plugin dev marketplace sync <base-kind>
```

For marketplace repository authors. Generates config files for other tools from a base kind.

Given base kind `claude`:

```
# Already exists (base):
.claude-plugin/marketplace.json
plugins/my-plugin/.claude-plugin/plugin.json
plugins/my-plugin/skills/my-skill/SKILL.md

# Generated for cursor:
.cursor-plugin/marketplace.json
plugins/my-plugin/.cursor-plugin/plugin.json

# Generated for codex:
.agents/plugins/marketplace.json              (format converted)
plugins/my-plugin/.codex-plugin/plugin.json
```

Key behaviors:

- `skills/` directory is shared across all kinds — no duplication
- `marketplace.json` is copied with format conversion where needed (Codex object source format)
- `plugin.json` content is copied into each kind's config dir
- Idempotent: safe to run multiple times, overwrites existing generated files
- Only modifies config files, never touches skill content

### 7. Implementation

| File                              | Purpose                                                                      |
| --------------------------------- | ---------------------------------------------------------------------------- |
| `src/schema/marketplace-kind.ts`  | `MarketplaceKind` type, path config per kind                                 |
| `src/schema/lock-file.ts`         | Add `marketplaceKind` to `RepositoryEntry`                                   |
| `src/service/skill-resolver.ts`   | Accept `marketplaceKind`, resolve correct marketplace path, normalize format |
| `src/cli/skill/add.ts`            | Detect available kinds, prompt selection, pass to resolver                   |
| `src/cli/dev/marketplace/sync.ts` | Dev sync command                                                             |
| `src/service/marketplace-sync.ts` | Core sync logic: read base, generate targets with format conversion          |
| `src/bin.ts`                      | Wire `dev marketplace sync` subcommand                                       |

## Impact

- **Lock file schema**: New `marketplaceKind` field on `RepositoryEntry`
- **Skill resolver**: Parameterized by marketplace kind, format normalization
- **Add command**: New kind detection and selection step
- **New subcommand**: `c-plugin dev marketplace sync <base-kind>`

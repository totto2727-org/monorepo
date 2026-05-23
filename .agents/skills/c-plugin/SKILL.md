---
name: c-plugin
description: Install, sync, and remove Claude Code (and Cursor / Codex) plugin skills from GitHub repos or local marketplace directories. Manages a lock file and symlinks under .agents/ so each repo gets a deterministic skill set across machines. Use when wiring a project to a Claude Code plugin marketplace, pinning specific plugin versions, or controlling which target directories receive skill symlinks.
allowed-tools: Bash(c-plugin:*)
---

# `c-plugin` — Claude Code Plugin manager

Lockfile-driven installer for **Claude Code marketplaces** (also handles Cursor and Codex marketplace formats). State lives in `.agents/skills-lock.json` at the nearest ancestor that has one (or `~/.agents/` when `--global`).

## Concepts

- **Marketplace root** — a directory containing `.claude-plugin/marketplace.json` (or `.cursor-plugin/` / `.codex-plugin/`). Its `plugins[].source` paths point at individual plugins; each plugin's `skills/<name>/SKILL.md` becomes an installable skill.
- **Lockfile** — `.agents/skills-lock.json` pins each repo's source, marketplace kind, enabled skills per plugin, and (for GitHub sources) commit hash.
- **Skill targets** — extra directories that receive the same skill symlinks (e.g. `~/.claude/skills/`). Managed via `c-plugin skill target add|remove`.

## Most common flows

```bash
# Add from a GitHub marketplace
c-plugin skill add totto2727-org/monorepo

# Add from a local marketplace (path must start with ./)
c-plugin skill add --local ./

# Install into the GLOBAL ~/.agents instead of the nearest project
c-plugin skill add --global totto2727-org/monorepo

# Re-create symlinks / prune skills that no longer exist upstream
c-plugin skill sync           # current project
c-plugin skill sync -g        # global
c-plugin skill sync -r        # walk down: every .agents/ found below cwd

# Update GitHub-sourced repos to latest commit and refresh lock
c-plugin skill update

# Remove a specific plugin or skill
c-plugin skill remove

# Manage where symlinks are placed
c-plugin skill target add  ~/.claude/skills/
c-plugin skill target remove ~/.claude/skills/
```

## `--local <path>` rules

- Path **must** start with `./` (current dir or below). `.` and absolute paths are rejected.
- The path is the **marketplace root** (the directory holding `.claude-plugin/marketplace.json`), not an individual plugin's `.claude-plugin/`.
- Stored in the lockfile as a path relative to `agentsRoot` (i.e. one level above `.agents/`).

## Sync tolerance

`skill add` / `skill sync` iterate every entry in the lockfile. A failure on one repo (broken GitHub source, missing remote, network error) is logged as `Skipped <source>: <message>` and the rest of the loop continues; the failing entry stays in the lockfile so it can be retried later.

## Dev (plugin authors)

Tools that operate on the marketplace repo you're **authoring** (run from the repo root with `.claude-plugin/` / `.cursor-plugin/` / `.codex-plugin/` directories).

### `c-plugin dev marketplace sync <base-kind>`

Takes one kind as the source of truth and **regenerates the other two kinds' marketplace files + per-plugin `plugin.json`** from it. Use this after editing the canonical marketplace so the others stay in sync.

```bash
c-plugin dev marketplace sync claude    # claude is source → write cursor + codex
c-plugin dev marketplace sync cursor    # cursor is source → write claude + codex
c-plugin dev marketplace sync codex     # codex  is source → write claude + cursor
```

What gets written:

| Kind     | marketplace path                                                | plugin path                           |
| -------- | --------------------------------------------------------------- | ------------------------------------- |
| `claude` | `.claude-plugin/marketplace.json`                               | `<plugin>/.claude-plugin/plugin.json` |
| `cursor` | `.cursor-plugin/marketplace.json`                               | `<plugin>/.cursor-plugin/plugin.json` |
| `codex`  | `.agents/plugins/marketplace.json` (note: not `.codex-plugin/`) | `<plugin>/.codex-plugin/plugin.json`  |

Format differences are handled automatically:

- **claude / cursor** share the same shape: `{ name, plugins: [{ name, description, source }] }`
- **codex** uses a richer shape: `source: { source: 'local', path: './...' }`, plus `category`, `policy`

Per-plugin `plugin.json` is **copied as-is** from the base kind's `<plugin>/<configDir>/plugin.json` to each target kind's directory (so the plugin metadata stays identical across formats). If the base plugin.json is missing, that copy step is silently skipped.

### Typical author workflow

```bash
# 1. Edit your canonical marketplace (say, the claude one)
vim .claude-plugin/marketplace.json

# 2. Mirror it to the others
c-plugin dev marketplace sync claude

# 3. Commit all touched files together
git add .claude-plugin .cursor-plugin .codex-plugin .agents/plugins
git commit
```

## File layout cheatsheet

```
project/
└── .agents/
    ├── skills-lock.json     # pinned state
    ├── skills/              # symlinks created by sync
    └── .cache/<owner>/<repo>/   # GitHub clones (full history, not shallow)
```

## Troubleshooting

- `Invalid local path` → use `./` prefix.
- `Repository not found` / `unable to read tree` on a GitHub entry → that entry is now skipped, not fatal. Remove with `c-plugin skill remove` or re-add fresh.
- Symlinks missing → run `c-plugin skill sync`.

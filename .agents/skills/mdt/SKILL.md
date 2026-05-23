---
name: mdt
description: Translate a Markdown file in-place (or to a sibling language file) using the opencode SDK. Use when localizing README.md, AGENTS.md, docs, or other Markdown into another language while preserving code blocks, fences, and frontmatter.
allowed-tools: Bash(mdt:*)
---

# `mdt` — Markdown translator (opencode-backed)

Wraps the [opencode](https://opencode.ai) SDK to translate a single Markdown file. Designed for doc localization where structure must round-trip: code fences, links, frontmatter, and tables stay intact.

## Usage

```bash
mdt --lang <code> [--model provider/model] [--force] <file>
```

- `<file>` — path to the source Markdown.
- `--lang, -l` — required. Target language code (e.g. `ja`, `ja-JP`, `en`).
- `--model, -m` — optional. `provider/model` form (e.g. `anthropic/claude-sonnet-4-5`). Defaults to whatever opencode is configured to use.
- `--force, -f` — overwrite an existing output file.

## Output filename convention

`mdt` writes a sibling file next to the source. For example:

- `README.md` + `--lang ja` → `README.ja.md`
- `AGENTS.md` + `--lang en` → `AGENTS.en.md`

Re-running without `--force` errors out if the target already exists (so you can re-translate selectively).

## Typical flows

```bash
# Localize the project README to Japanese
mdt --lang ja README.md

# Re-translate after upstream changes
mdt --lang ja --force README.md

# Pin a specific model
mdt --lang en --model anthropic/claude-sonnet-4-6 docs/AGENTS.md
```

## Prerequisites

- `opencode` must be installed and authenticated locally (the CLI delegates to the SDK).
- The chosen `--model` must be available in your opencode provider config.

## Limits

- One file per invocation. For batch use, drive `mdt` from a shell loop or `xargs`.
- Long files may be split internally by opencode; expect the output to be assembled before write, not streamed.

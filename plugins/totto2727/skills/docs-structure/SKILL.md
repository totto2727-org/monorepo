---
name: docs-structure
description: >-
  Rules for README.md vs AGENTS.md (CLAUDE.md) separation.
  README.md is human-facing: overview, setup, license.
  AGENTS.md is AI-facing: commands, architecture, rules, tools.
  Never mix audiences — no AI context in README, no human setup guides in AGENTS.
  Triggers on: "create README", "write AGENTS.md", "set up CLAUDE.md",
  "project documentation", "documentation structure", "add docs to package",
  "initialize repo docs".
metadata:
  author: totto2727
  version: 1.0.0
---

# Docs Structure — README.md vs AGENTS.md (CLAUDE.md)

Use Case Category: **Content Authoring**
Design Pattern: **Decision Flow** (which audience → which file)

Defines the strict separation between human-facing README.md and AI-facing AGENTS.md (aliased as CLAUDE.md via symlink).

## Rule (CRITICAL)

| File        | Audience              | Content                                                                                                      |
| ----------- | --------------------- | ------------------------------------------------------------------------------------------------------------ |
| `README.md` | **End users**         | Overview + usage **first**, then key features, prerequisites, setup, license. Contributor info is secondary. |
| `AGENTS.md` | **AI agents**         | Language rules, detailed commands, architecture, conventions, tool references, constraints                   |
| `CLAUDE.md` | **AI agents (alias)** | Symlink to `AGENTS.md` — never a separate file                                                               |

**NEVER mix audiences in a single file.**

## Decision Flow

When you need to add or update project documentation, ask:

```
Is this content for humans or for AI agents?
```

### README.md (End-user-facing)

README.md is for **end users first**. Lead with what they can do with this project. Contributor / developer content goes in AGENTS.md and is only referenced from README via a short link.

**Section order (top → bottom, priority high → low):**

1. **Title + one-paragraph overview** — what this does, who it's for, the concrete capability
2. **Usage** — the primary CLI invocation, library entry point, or service endpoint with a minimal runnable example
3. **Key features** — short bullet list of capabilities
4. **Prerequisites** — only what end users need to run the project
5. **Setup** — minimal install steps for end users
6. **Development** — one-line link to AGENTS.md, nothing more
7. **License**

Content belongs in README.md when:

- ✅ Project overview / elevator pitch (what users get)
- ✅ Usage examples (CLI invocations, library snippets, service endpoints)
- ✅ Key features and capabilities (user-visible)
- ✅ Prerequisites & installation for end users
- ✅ Minimal setup steps for end users
- ✅ Links to external resources and user-facing documentation
- ✅ License and ownership
- ✅ One-line link to AGENTS.md for contributors

Content that does **NOT** belong in README.md (or only as a brief mention with a link):

- ❌ Detailed project / directory structure (→ AGENTS.md; users don't care)
- ❌ Detailed CLI command reference for contributors (→ AGENTS.md)
- ❌ Build / test / lint commands (→ AGENTS.md)
- ❌ Architecture deep-dives (→ AGENTS.md)
- ❌ AI-specific rules and constraints (→ AGENTS.md)
- ❌ Internal conventions and code patterns (→ AGENTS.md)
- ❌ Tool configuration details for AI agents (→ AGENTS.md)
- ❌ "How AI should work on this project" instructions (→ AGENTS.md)

### AGENTS.md (AI-facing)

Content belongs in AGENTS.md when:

- ✅ Language rules and defaults
- ✅ Detailed command reference (build, test, lint, deploy)
- ✅ Execution rules and constraints
- ✅ Repository structure (machine-readable format like `tree`/`eza`)
- ✅ Architecture details (package management, path aliases)
- ✅ Development tools and their usage
- ✅ Conventions and code patterns
- ✅ AI-specific behavior rules ("never use npx", "always check X before Y")
- ✅ Submodule/workspace relationships and task orchestration

Content that does **NOT** belong in AGENTS.md:

- ❌ "Getting started" guides (→ README.md)
- ❌ Project descriptions for new users
- ❌ Installation instructions
- ❌ License information
- ❌ Marketing/feature highlights

### CLAUDE.md

`CLAUDE.md` must be a symlink to `AGENTS.md`:

```bash
ln -s AGENTS.md CLAUDE.md
```

Never create a separate CLAUDE.md file. This ensures Claude and other AI tools see the same content.

## When Creating or Updating These Files

### New Package / Project

1. If the user asks to create README.md → use [templates/README.template.md](templates/README.template.md) as a starting point
2. If the user asks to create AGENTS.md → use [templates/AGENTS.template.md](templates/AGENTS.template.md) as a starting point
3. After creating AGENTS.md → remind the user to symlink CLAUDE.md

### Updating Existing

1. Read both files first to understand current structure
2. Classify the new content per the Decision Flow above
3. Place content in the correct file only
4. If content spans audiences → alert the user and propose the split

## Detailed Content Classification

See [references/separation-principles.md](references/separation-principles.md) for a comprehensive table of content types and which file they belong in.

## Anti-Patterns

### ❌ Adding AI rules to README.md

```markdown
# My Project

## For AI Agents

- Never use npx — always use vp run
```

**Fix**: Move AI rules to AGENTS.md. In README.md, link: "See [AGENTS.md](./AGENTS.md) for development commands."

### ❌ Adding setup instructions to AGENTS.md

```markdown
# my-project

## Setup

1. Install Nix
2. Run `nix develop`
```

**Fix**: Move setup to README.md. In AGENTS.md, reference: "Development environment is managed by Nix flakes (see README.md for setup)."

### ❌ Separate CLAUDE.md and AGENTS.md with different content

**Fix**: Pick AGENTS.md as canonical. Make CLAUDE.md a symlink: `ln -sf AGENTS.md CLAUDE.md`.

### ❌ Per-package AGENTS.md that duplicates root

**Fix**: AGENTS.md at repo root is the canonical file for all AI context. Only create per-package AGENTS.md if the package has unique AI context not covered by root.

## Platform Notes

- **This project (monorepo)**: CLAUDE.md is a symlink to AGENTS.md at repo root. No per-package AGENTS.md files exist.
- The root AGENTS.md serves as the single AI context file for all packages.
- Skills in `plugins/totto2727/skills/` use their own SKILL.md for skill-specific AI context — this is NOT the same as project AGENTS.md.

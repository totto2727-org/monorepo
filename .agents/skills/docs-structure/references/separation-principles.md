# Content Classification Guide

Comprehensive table mapping content types to target file.

## By Content Type

| Content                             | README.md               | AGENTS.md | Notes                                               |
| ----------------------------------- | ----------------------- | --------- | --------------------------------------------------- |
| Project description (for end users) | ✅                      | ❌        | What it does, who it's for — top of README          |
| Usage examples                      | ✅                      | ❌        | Primary CLI / library entry — second after overview |
| Project structure (any form)        | ❌                      | ✅        | Users don't care; AI / contributors do              |
| Prerequisites (end users)           | ✅                      | ❌        | Only tools end users need to run it                 |
| Installation steps (end users)      | ✅                      | ❌        | Minimal install for end users                       |
| Contributor setup                   | ❌                      | ✅        | Full dev environment setup                          |
| Key features                        | ✅                      | ❌        | Short user-visible capability bullets               |
| Language rules                      | ❌                      | ✅        | "Use English by default"                            |
| Execution rules                     | ❌                      | ✅        | "Never use npx"                                     |
| CLI command reference               | Brief summary → link    | ✅        | Full reference with flags/options                   |
| Build commands                      | ❌                      | ✅        | Detailed build task definitions                     |
| Test commands                       | ❌                      | ✅        | How to run tests, filters                           |
| Lint/format commands                | ❌                      | ✅        | `vp run check`, `vp run fix`                        |
| Architecture (any form)             | ❌                      | ✅        | Internal design, not for end users                  |
| Package management                  | ❌                      | ✅        | Bun workspaces, catalogs                            |
| Path aliases                        | ❌                      | ✅        | `#@/` conventions                                   |
| Development tooling                 | ❌                      | ✅        | Tools list with usage                               |
| Code conventions                    | ❌                      | ✅        | Patterns, formatting, naming                        |
| AI constraints                      | ❌                      | ✅        | Behavior rules for AI agents                        |
| Task definitions                    | ❌                      | ✅        | Vite+ task config format                            |
| CI/CD instructions                  | ❌                      | ✅        | Pipeline commands                                   |
| License                             | ✅                      | ❌        | Legal info                                          |
| Contributing guide                  | Link to CONTRIBUTING.md | ❌        | Separate file recommended                           |
| External doc links                  | ✅                      | ❌        | References to external resources                    |
| Repository links                    | ✅                      | ✅        | Cross-references to each other                      |

## By Audience

### README.md serves (priority order):

1. **End users (primary)** — What is this? How do I use it?
2. **Evaluators** — Should I adopt this project?
3. **New contributors (only briefly)** — Where do I go for development docs? (one-line link to AGENTS.md)

### AGENTS.md serves:

1. **AI coding assistants** — How do I work in this codebase?
2. **CI/CD systems** — What are the standard commands?
3. **Automated tooling** — What conventions must be followed?

## Boundary Rules

### The "End-User Test" for README.md

> Would an end user who just wants to **use** this project (not develop it) need this information?

- Yes → README.md
- No → AGENTS.md (or skip entirely)

Project structure, build commands, contributor workflows, and architecture all fail this test — they belong in AGENTS.md.

### The "AI Agent Test" for AGENTS.md

> Would an AI coding assistant need this information to correctly modify or build this project?

- Yes → AGENTS.md
- No → Consider if it's needed at all

### The "Shared Content" Rule

If content is needed by both audiences:

1. Write the **detailed version** for the primary audience
2. Add a **brief summary + link** in the other file

Example:

- README.md: `See [AGENTS.md](./AGENTS.md#development-commands) for full command reference.`
- AGENTS.md: `Development environment is managed by Nix flakes (see [README.md](./README.md#setup) for setup).`

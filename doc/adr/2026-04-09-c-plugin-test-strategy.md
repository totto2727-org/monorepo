---
confirmed: false
---

# ADR: c-plugin Integration Test Strategy

## Context

The c-plugin CLI tool has grown to include multiple services (lock-file, symlink, cache, skill-resolver, sync) and CLI commands with no test coverage. Before extending functionality or fixing bugs, a testing foundation is needed to catch regressions and validate behavior.

Key constraints that shape the testing strategy:

1. **All filesystem operations use `node:fs/promises` directly** — not Effect's `@effect/platform` FileSystem service. This rules out in-memory filesystem substitution via Effect layers.
2. **Git operations use `execFile`** — requiring network access for real execution.
3. **CLI commands use interactive `Prompt.multiSelect`** — making end-to-end CLI testing impractical without refactoring.
4. **All services accept `agentsDir` as a parameter** — making path redirection to temporary directories straightforward.

## Decision

### 1. Test Scope

Service-level integration tests covering all core business logic modules:

| Module                      | Test File                | Mock Required |
| --------------------------- | ------------------------ | ------------- |
| `service/lock-file.ts`      | `lock-file.test.ts`      | None          |
| `service/symlink.ts`        | `symlink.test.ts`        | None          |
| `service/skill-resolver.ts` | `skill-resolver.test.ts` | None          |
| `service/cache.ts`          | `cache.test.ts`          | Git           |
| `service/sync.ts`           | `sync.test.ts`           | Git           |
| `lib/paths.ts`              | `paths.test.ts`          | None          |

CLI command tests are excluded from this round due to interactive prompt dependencies.

### 2. Filesystem Strategy

Real temporary directories created per test via `Fs.mkdtemp`, cleaned up in `afterEach`:

- `setupTestContext()` creates a temp dir and returns `{ agentsDir, cleanup }`
- `buildFakeRepoFixture()` creates the directory structure that `git clone` would produce (marketplace.json, SKILL.md files)
- `writeLockFile()` pre-populates a lock file for tests that need one
- `ensureAgentsDirs()` creates the `.cache/` and `skills/` directories

All helpers live in `src/service/_test-helper.ts`.

### 3. Git Mock Strategy

Git operations are mocked via `vi.mock('#@/service/git.ts')` using a shared mock module at `src/service/_git-mock.ts`. The mock:

- `clone` creates the destination directory (simulating a real clone)
- `checkout`, `pull`, `revParseHead`, `checkInstalled` are no-ops or return fixed values
- Tests that need specific repository content use `buildFakeRepoFixture()` to create the expected directory structure

### 4. Test Infrastructure

- **Framework**: vitest via vite-plus (`vp test`)
- **Imports**: `import { describe, expect, test } from 'vite-plus/test'`
- **File location**: Colocated with source files (e.g., `lock-file.test.ts` next to `lock-file.ts`)
- **Test execution**: From monorepo root: `npx vp test --run js/app/c-plugin`

### 5. Known Issues Documented

- `lock-file.ts`: `parseJson` throws synchronously inside `Effect.flatMap`, producing a defect (Die) that `orElseSucceed` cannot catch. The corrupt JSON test documents this behavior.

## Impact

- 38 integration tests across 6 test files
- New files: `_test-helper.ts`, `_git-mock.ts`, 6 test files, `paths.test.ts`
- No changes to production code
- Tests run from monorepo root (c-plugin's `pack` config conflicts with vitest direct execution)

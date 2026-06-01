# monorepo

## Language Rules

- Use English by default.
- Use Japanese only for user-facing temporary outputs that are not final artifacts.

## Repository Structure

```bash
eza --tree -L 2 -D js mbt go
```

## Development Commands

### Execution Rules

- **Never use `npx` or `bunx`** — always use `vp run`, `vp exec`, or `vpx` in that order
- All commands must be run from the repository root unless noted otherwise
- All `check` / `fix` / `test` / `setup` / `build` are Vite+ tasks defined in `vite.config.ts`. The `--cache` flag is no longer required — caching is on by default

### Standard Tasks

`vp run <task>` runs the task in the current package; `-r` fans it out across the workspace.

```bash
vp run check                  # Format / lint / type check (root task: vp check)
vp run fix                    # Auto-fix lint / format, then type check (root task: vp check --fix)
vp run test                   # Run Vitest (root task: vp test)
vp run -r setup               # Run every package's setup task (e.g. wrangler types,
                              # paraglide-js compile, tsr generate, atlas-to-kysely)
vp run -r build               # Build every package; per-package build dependsOn its setup
vp run --parallel ci          # Run check / test / build across the workspace ignoring
                              # task ordering. Run `vp run -r setup` first to warm the
                              # cache so generated outputs already exist
```

### Targeting a single package

```bash
vp run --filter <project> <task>     # e.g. vp run --filter saas-example build
vp run <project>#<task>              # e.g. vp run saas-example#setup:tsr
```

When the above is impractical, `cd` into the package first and run `vp run <task>`.

### Adjusting cache and concurrency

```bash
vp run --no-cache <task>             # Skip the cache for this invocation
vp run --concurrency-limit 0 <task>  # Unlimited concurrency (default: 4)
vp run -v <task>                     # Show the per-task cache hit / miss summary
```

### Per-test commands

```bash
vp test run <test-file>              # Run a specific test file
vp test related <source>             # Run tests related to a source file
```

### Defining new tasks

Tasks are declared inside each package's `vite.config.ts` under `run.tasks`:

```ts
run: {
  tasks: {
    setup: { command: '', dependsOn: ['setup:foo', 'setup:bar'] },
    'setup:foo': { command: 'tool generate', input: [{ auto: true }, '!output/**'] },
    build: { command: 'vp build', dependsOn: ['setup'] },
  },
}
```

`@totto2727/fp/vite`'s `defineTaskInputFromOutput` centralises the
self-output exclusion globs across `setup:*` and `build`. Vite+ rejects
a task and a `package.json` script that share a name — when promoting
a script to a task, drop the script.

### MoonBit Commands

MoonBit uses the repository-root `moon.work`. Root `vite.config.ts`
exposes `mbt:check` / `mbt:fix` / `mbt:test`; build remains a
package task collected by `w:build`.

```bash
vp run mbt:check # moon check
vp run mbt:fix   # moon fmt
vp run mbt:test  # moon test
vp run w:build   # includes MoonBit package builds
```

Drop down to `moon` directly only for non-task subcommands:

```bash
moon info          # Update generated interface files (.mbti)
moon test --update # Update snapshot tests
moon coverage analyze > uncovered.log
```

## Architecture

### Package Management

- pnpm workspaces with catalog mode for centralized dependency version management
- All dependency versions are defined in `pnpm-workspace.yaml` catalogs

### Path Aliases

- `#@/` - Application internal imports via Node.js imports field (configured in each `package.json`)

## Development Tools

- **Devbox** - Development environment manager
- **Vite+** (`vp`) - Unified toolchain wrapping Vite, Vitest, and monorepo task orchestration
- **Ultracite** - Code quality (Oxlint + Oxfmt) — `ultracite check` / `ultracite fix`
- **Grit** - Additional code analysis and auto-fixes
- **Renovate** - Automated dependency updates (weekly, Saturday 00:00)
- **Just** - Additional task definitions (`Justfile`)

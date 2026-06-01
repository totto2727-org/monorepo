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
- The task runner is always Vite+ (`vp`) regardless of language. Use Vite+ tasks for JavaScript, MoonBit, Go, and any future language-specific automation.
- Basic task names are `setup`, `fix`, `check`, `build`, and `test`. A project may omit tasks that are not needed.
- All tasks are defined in `vite.config.ts`. The `--cache` flag is no longer required — caching is on by default.

### Task Layers

#### Project-level tasks

Project-level tasks live in each project's `vite.config.ts`. They use the basic task names directly and are the unit collected by workspace fan-out.

```bash
vp run --filter <project> setup
vp run --filter <project> fix
vp run --filter <project> check
vp run --filter <project> build
vp run --filter <project> test
```

Use only the tasks that the project defines. For example, a package may expose `build` but omit `test`.

#### Language-level root tasks

Languages whose toolchains support workspace-root execution expose root tasks as `<language>:<basic-task>`. These tasks must run without `-r` and without file arguments.

```bash
vp run js:check               # JavaScript format / lint / type check
vp run js:fix                 # JavaScript auto-fix, then type check
vp run js:test                # JavaScript tests
vp run mbt:check              # MoonBit check from repository-root moon.work
vp run mbt:fix                # MoonBit format from repository-root moon.work
vp run mbt:test               # MoonBit tests from repository-root moon.work
```

Do not create root language-level tasks for commands that require `-r`, package filters, or file paths. Define those in the relevant project and let `w:*` collect them.

#### Root aggregate tasks

Root aggregate tasks combine language-level root tasks. They are not full workspace fan-out tasks; use them when the operation is implemented by root language tasks such as `js:*` and `mbt:*`.

```bash
vp run setup                  # Root setup aggregate, when defined
vp run fix                    # Root language fix aggregate
vp run check                  # Root language check aggregate
vp run build                  # Root build aggregate, when defined
vp run test                   # Root language test aggregate
```

#### Repository-level workspace fan-out tasks

True repository-level execution uses the `w:<basic-task>` form. These tasks run the corresponding project-level task across the workspace.

```bash
vp run w:setup                # Run every package's setup task
vp run w:fix                  # Run every package's fix task
vp run w:check                # Run every package's check task
vp run w:build                # Run every package's build task
vp run w:test                 # Run every package's test task
vp run --parallel ci          # Run check / test / build across the workspace ignoring task ordering
```

Run `vp run w:setup` first when generated outputs must exist before parallel CI-style execution.

### Targeting a single package

```bash
vp run --filter <project> <task>     # e.g. vp run --filter saas-example build
vp run <project>#<task>              # e.g. vp run saas-example#setup:tsr
```

When the above is impractical, `cd` into the package first and run `vp run <task>`.

Project-specific commands beyond `setup` / `fix` / `check` / `build` / `test` belong in that project's documentation. If you need file-level execution, inspect the relevant project's `package.json` and `vite.config.ts` and mirror the command shape they define.

Multi-step scripts that are not workspace fan-out tasks belong in the `Justfile`. Use Just tasks for operational workflows such as database-related procedures.

### Adjusting cache and concurrency

```bash
vp run --no-cache <task>             # Skip the cache for this invocation
vp run --concurrency-limit 0 <task>  # Unlimited concurrency (default: 4)
vp run -v <task>                     # Show the per-task cache hit / miss summary
```

### File-level test commands

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

# monorepo

## Repository Structure

```bash
eza --tree -L 2 -D js mbt go
```

## Development Commands

### Execution Rules

- **Never use `npx` or `bunx`** — always use `vp run`, `vp exec`, or `vpx` in that order
- All commands must be run from the repository root unless noted otherwise

### Workspace-wide NPM Scripts

```bash
vp run --cache -r  <script>   # e.g. check, fix, prebuild, build, test
```

### Single Project NPM Scripts (from root)

```bash
vp run --cache --filter <project> <script>   # e.g. vp run --filter bw build
```

### Built-in Commands (from root)

```bash
vp check           # Format, lint, and type check
vp check --fix     # Auto-fix linting and formatting issues, then type check
vp test                   # Run all tests by Vitest
vp test run <test-file>   # Run a specific test file
vp test related <source>  # Run tests related to a source file
```

### Project-local Commands (requires cd)

When the above methods cannot be used, cd into the project directory first:

```bash
vp run <script>    # e.g. cd js/app/bw && vp run build
```

### MoonBit Commands

For `mbt/` workspace projects:

```bash
moon build         # Build MoonBit packages
moon check         # Type check MoonBit code
moon fmt           # Format MoonBit code
moon test          # Run MoonBit tests
moon info          # Update generated interface files (.mbti)
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
- **Go Task** - Additional task definitions (`Taskfile.yml`)

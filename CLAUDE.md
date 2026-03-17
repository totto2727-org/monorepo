# monorepo

## Repository Structure

```bash
eza --tree -L 2 -D js mbt go
```

## Development Commands

### Workspace Tasks

- `vp run -r check` - Run format, lint, and type check across the entire workspace
- `vp run -r fix` - Auto-fix linting and formatting issues and type check across the entire workspace
- `vp run -r prebuild` - Prepare workspace for build (e.g., generate types)
- `vp run -r build` - Build all workspace projects
- `vp run -r test` - Run tests across the entire workspace

### TypeScript Commands

For `js/` workspace projects:

- `vp build` - Build by Vite
- `vp check` - Format, Lint, and type check
- `vp check --fix` - Auto-fix linting and formatting issues and type check
- `vp test` - Run tests by Vitest

### MoonBit Commands

For `mbt/` workspace projects:

- `moon build` - Build MoonBit packages
- `moon check` - Type check MoonBit code
- `moon fmt` - Format MoonBit code
- `moon test` - Run MoonBit tests
- `moon info` - Update generated interface files (.mbti)

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

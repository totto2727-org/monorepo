# monorepo

## Repository Structure

Multi-language monorepo (TypeScript + MoonBit) using pnpm workspaces and Vite+ for task orchestration.

### Applications

- `js/app/rss-graphql/` - GraphQL API server for RSS feed processing (Hono + Pothos + Cloudflare Workers)
- `js/app/saas-example/` - SaaS demo application (React 19 + TanStack Start + Cloudflare Workers)

### Packages

- `js/package/fp/` - `@totto2727/fp` functional programming utility library (NPM + JSR)
- `js/package/ui/` - `@package/ui` React UI component library (Shadcn/UI base + Tailwind CSS v4)
- `mbt/package/geo/` - `@totto2727/geo` GeoJSON and geospatial library (MoonBit)

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
- Workspace packages: `js`, `js/app/*`, `js/package/*`, `mbt/package/*`

### Path Aliases

- `#@/` - Application internal imports via Node.js imports field (configured in each `package.json`)
- `js/app/rss-graphql`: `#@/*` maps to `./app/*`
- `js/app/saas-example`: `#@/*` maps to `./src/*`

### Type Checking

- TypeScript projects use `vp check`
- MoonBit projects use `moon check`

## Development Tools

- **Devbox** - Development environment manager
- **Vite+** (`vp`) - Unified toolchain wrapping Vite, Vitest, and monorepo task orchestration
- **Ultracite** - Code quality (Oxlint + Oxfmt) — `ultracite check` / `ultracite fix`
- **Grit** - Additional code analysis and auto-fixes
- **Lefthook** - Git hooks (pre-commit runs `vp run fix`)
- **Renovate** - Automated dependency updates (weekly, Saturday 00:00)
- **Go Task** - Additional task definitions (`Taskfile.yml`)

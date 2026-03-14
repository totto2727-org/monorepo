# monorepoo

## Repository Structure

Multi-language monorepo (TypeScript + MoonBit) using Bun workspaces and Turborepo for task orchestration.

### Applications

- `js/app/rss-graphql/` - GraphQL API server for RSS feed processing (Hono + Pothos + Cloudflare Workers)
- `js/app/saas-example/` - SaaS demo application (React 19 + TanStack Start + Cloudflare Workers)

### Packages

- `js/package/fp/` - `@totto2727/fp` functional programming utility library (NPM + JSR)
- `js/package/ui/` - `@package/ui` React UI component library (Shadcn/UI base + Tailwind CSS v4)
- `mbt/package/geo/` - `@totto2727/geo` GeoJSON and geospatial library (MoonBit)

## Development Commands

### Root Scripts

- `bun run check` - Run all checks in parallel (Grit + Ultracite)
- `bun run fix` - Run all auto-fixes sequentially (Grit + Ultracite)

### Turbo Tasks

Run from root to execute across the entire workspace:

- `turbo build` - Build all projects with dependency graph optimization
- `turbo check` - Run type checks across all projects
- `turbo fix` - Auto-fix linting and formatting issues
- `turbo test` - Run tests across all projects
- `turbo deploy` - Deploy projects
- `turbo prebuild` - Generate types, routes, and configuration files

### MoonBit Commands

For `mbt/` workspace projects:

- `moon build` - Build MoonBit packages
- `moon check` - Type check MoonBit code
- `moon fmt` - Format MoonBit code
- `moon test` - Run MoonBit tests
- `moon info` - Update generated interface files (.mbti)

## Architecture

### Package Management

- Bun workspaces with catalog mode for centralized dependency version management
- All dependency versions are defined in root `package.json` catalogs
- Workspace packages: `js`, `js/app/*`, `js/package/*`, `mbt/package/*`

### Path Aliases

- `#@/` - Application internal imports via Node.js imports field (configured in each `package.json`)
- `js/app/rss-graphql`: `#@/*` maps to `./app/*`
- `js/app/saas-example`: `#@/*` maps to `./src/*`

### Type Checking

- `tsgo` is used for TypeScript type checking in most projects
- MoonBit projects use `moon check`

## Development Tools

- **Devbox** - Development environment manager (bun@1, nodejs@latest)
- **Turborepo** - Monorepo task orchestration and caching
- **Ultracite** - Code quality (Oxlint + Oxfmt) — `ultracite check` / `ultracite fix`
- **Grit** - Additional code analysis and auto-fixes
- **Lefthook** - Git hooks (pre-commit runs `turbo fix`)
- **Renovate** - Automated dependency updates (weekly, Saturday 00:00)
- **Go Task** - Additional task definitions (`Taskfile.yml`)

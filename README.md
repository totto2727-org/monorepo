# Monorepo

A multi-language monorepo (TypeScript + MoonBit) using pnpm workspaces and Vite+.

## Project Structure

### Applications

- **js/app/rss-graphql** - GraphQL API for RSS Feed Processing
  - Hono + Pothos GraphQL + Cloudflare Workers
  - RSS feed fetching, parsing, and GraphQL schema integration
  - Effect for functional error handling

- **js/app/saas-example** - Full-stack SaaS Demo Application
  - React 19 + TanStack Start (Router, Query, Store, Form, DB)
  - Hono backend on Cloudflare Workers
  - Paraglide-JS i18n (Japanese, English)
  - better-auth authentication
  - Storybook for component development

### Packages

- **js/package/fp** - `@totto2727/fp` Functional Programming Utilities
  - Re-exports: Effect, option-t, Temporal, change-case, velona
  - Custom: Effect/option-t bridge, CUID generator, duration formatting
  - Shared TypeScript configs (bun, node, react, tanstack-start, etc.)
  - Published to NPM and JSR (raw `.ts` source files)

- **js/package/ui** - `@package/ui` React UI Component Library
  - Shadcn/UI base + Tailwind CSS v4
  - Lucide React icons
  - CVA (class-variance-authority) for component variants

- **mbt/package/geo** - `@totto2727/geo` GeoJSON Library
  - MoonBit language
  - RFC 7946 compliant GeoJSON implementation
  - Turf.js-like geospatial algorithms

## Tech Stack

### Languages & Runtimes

- TypeScript (Bun, Cloudflare Workers)
- MoonBit (geospatial processing)

### Frameworks & Libraries

- React 19, TanStack ecosystem (Router, Query, Store, Form, DB)
- Hono (web framework), Vite (build tool)
- Cloudflare Workers (serverless runtime)
- Tailwind CSS v4 (styling)
- Effect + option-t (functional programming)

### Build & Quality Tools

- Vite+ (unified toolchain & task orchestration)
- Ultracite (Oxlint + Oxfmt for linting/formatting)
- Grit (code analysis)
- Vitest (testing), Storybook (component development)

## Development Setup

### Requirements

- [Devbox](https://www.jetify.com/devbox) (provides nodejs)

### Installation

```bash
# Enter development environment
devbox shell

# Install dependencies
vp i
```

## Development Commands

## Workspace Tasks

```bash
# Check all workspace projects
vp run -r check

# Fix all workspace projects
vp run -r fix

# Prepare workspace for build, dev, test
vp run -r prebuild

# Build all projects
vp run -r build

# Run tests
vp run -r test
```

### TypeScript

```bash
# Lint, format check, and Type check
vp check

# Lint and format auto-fix
vp check --fix

# Prepare workspace for build, dev, test
vp run prebuild

# Build all projects
vp build

# Run tests
vp test
```

### MoonBit

```bash
# Build
moon build

# Test
moon test

# Format
moon fmt

# Lint
moon check
```

## Documentation

- `CLAUDE.md` - AI assistant guidance and project overview
- Sub-project `CLAUDE.md` files - Project-specific guidance
- Sub-project `README.md` files - Project-specific documentation

## License

Private repository (`@totto2727/fp` is MIT licensed)

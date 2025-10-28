# Package Development Guide

Common tools, settings, and directory structure for packages in this monorepo.

## Quick Reference

- **Main coding standards**: See @docs/coding-rules.md
- **Lint rules**: See @docs/ultracite.md
- **Repository structure**: See @CLAUDE.md

## Common Tools

### Build Tool

- **tsdown**: Used for building TypeScript packages
  - Configured via `tsdown.config.ts` in each package
  - Supports multiple entry points and output formats
  - Automatically handles type declarations

## Standard Directory Structure

```txt
package/{package-name}/
├── src/
│   ├── index.ts          # Main entry point with namespace exports
│   ├── {feature}.ts      # Feature modules
│   └── {feature}/        # Feature directories (if complex)
├── package.json
├── tsconfig.json
├── tsdown.config.ts      # Build configuration
├── biome.jsonc           # extends root biome.jsonc
├── dprint.json           # extends root dprint.json
└── .gitignore            # ignore dist
```

### Entry Point Pattern

Use namespace exports at `src/index.ts`:

```typescript
// biome-ignore lint/performance/noBarrelFile: package endpoint
export * as Feature from "./feature.js"
export * as AnotherFeature from "./another-feature.js"
```

## Package Configuration

### Dependency Management

**IMPORTANT**: Follow these rules for dependency placement:

- **peerDependencies + devDependencies**: Base frameworks and libraries (React, Hono, Effect, etc.)
  - Place in `peerDependencies` to avoid version conflicts
  - Also add to `devDependencies` for development
  - Examples: `react`, `react-dom`, `hono`, `drizzle-orm`, `@totto/function`

- **dependencies**: Libraries used only within the package or re-exported
  - Internal implementation details
  - Re-exported utilities
  - Examples: `@package/constant`, `@hono/cloudflare-access`

### package.json

**IMPORTANT**: Never use `main` or `types` fields. Use `exports` field instead.

```json
{
  "name": "@package/{name}",
  "type": "module",
  "version": "0.0.0",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsdown",
    "check": "tsgo",
    "dev": "tsdown --watch",
    "test": "vitest run --passWithNoTests"
  }
}
```

For packages with multiple entry points:

```json
{
  "exports": {
    "./feature-a": {
      "import": "./dist/feature-a.js",
      "types": "./dist/feature-a.d.ts"
    },
    "./feature-b": {
      "import": "./dist/feature-b.js",
      "types": "./dist/feature-b.d.ts"
    }
  }
}
```

### tsconfig.json

For Node.js packages:

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "exclude": ["dist"],
  "extends": ["@totto/function/tsconfig/node24", "@totto/function/tsconfig/lib"]
}
```

For React packages:

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "exclude": ["dist"],
  "extends": ["@totto/function/tsconfig/react", "@totto/function/tsconfig/lib"],
}
```

# Import/Export Conventions

This document defines conventions for importing and exporting modules.

## Basic Policy

### Use namespace imports as the standard

Namespace imports eliminate the need to include file or hierarchy names in function names:

```typescript
import * as Tenant from "@package/tenant/hono"
Tenant.DB.live
Tenant.DB.make(...)
```

**Not recommended** (verbose naming when no namespace):

```typescript
import { makeTenantDatabaseInitializer } from "@package/tenant/hono/db"
```

## Namespace Exports

Use namespace exports at package entry points:

```typescript
export * as User from "./schema/user.js"
export * as Organization from "./schema/organization.js"
export * as DB from "./hono/db.js"
```

**Guidelines**:

- Use PascalCase for namespace names
- Suppress barrel file warnings with explicit reason:

```typescript
// biome-ignore lint/performance/noBarrelFile: package endpoint
```

## Import Patterns

### Repository Internal Code

For code in `@package/*` or `@/*` directories, use **namespace imports**:

```typescript
import * as Tenant from "@package/tenant/hono"
import * as CloudflareAccess from "@package/tenant/hono/cloudflare-access"
import * as Drizzle from "@/feature/drizzle.js"
```

### Repository External Code

For third-party libraries, use **named imports**:

```typescript
import { Layer, Effect, Context } from "@totto/function/effect"
import { Hono } from "hono"
import { drizzle } from "drizzle-orm/d1"
```

### Type-Only Imports

Always use `import type` for type-only imports (mandatory):

```typescript
import type { Context } from "hono"
import type { Option } from "@totto/function/effect"
```

### Mixed Imports

Combine runtime and type imports when both are needed:

```typescript
import { Context, Layer, type Option } from "@totto/function/effect"
```

## File Extensions

Always include `.js` extension for relative imports (ESM compatible):

```typescript
import * as Drizzle from "./drizzle.js"
import { Database } from "./drizzle.js"
import * as User from "../schema/user.js"
```

## Path Aliases

Configure `@/` alias in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./app/*"]
    }
  }
}
```

Usage:

```typescript
import * as Drizzle from "@/feature/drizzle.js"
import { getContext } from "@/feature/hono.js"
```

## Barrel File Restrictions

Barrel files are prohibited by default (Biome lint rule).

When necessary, always include `// biome-ignore` comment with reason:

```typescript
// biome-ignore lint/performance/noBarrelFile: package endpoint
// biome-ignore lint/performance/noBarrelFile: required all table
```

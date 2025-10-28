# Layer Patterns

This document defines patterns for Effect-TS Layer and dependency injection.

## Layer Naming Conventions

Follow official documentation and use the following naming:

| Naming Pattern | Usage                                                        |
| -------------- | ------------------------------------------------------------ |
| `live`         | For production environment Layer                             |
| `dev`          | For develop or test environment Layer                        |
| `test`         | For test-only Layer                                          |
| `layer`        | When multiple definitions needed for non-environment reasons |

### Choosing between constant or function

- **Constant**: When no parameters needed
- **Function**: When parameters needed (dummy values, app-dependent implementations, etc.)

### Usage examples

**Production Layer (constant)**:

```typescript
export const live = Layer.succeed(User, () => getContext<Env>().var.user)
```

**Development Layer (function)**:

```typescript
export const dev = (user: { id?: string; organizationIDArray: string[] }) =>
  Layer.succeed(User, () => user)
```

### Invocation example

```typescript
import * as Tenant from "@package/tenant/hono"
import * as JWT from "@package/tenant/hono/cloudflare-access/jwt"

const app = createApp.pipe(
  Effect.provide(Tenant.DB.live),
  Effect.provide(Tenant.User.live),
  Effect.provide(JWT.User.dev({ id: "test", organizationIDArray: [] })),
  Effect.provide(Tenant.DB.make(() => getContext().var.database)),
  Effect.runSync,
)
```

## Context.Tag Definition Patterns

Choose the appropriate pattern based on usage:

- **Two-stage definition**: Only for packages (`@package/*`)
- **Inline definition**: For applications (`@app/*`) that won't be used as packages

### Two-stage Definition (Packages Only)

Use when the code will be published as a package and consumed by other projects:

```typescript
const UserClass: Context.TagClass<
  User,
  "@package/tenant/hono/user/User",
  () => Option.Option<typeof schema.Type>
> = Context.Tag("@package/tenant/hono/user/User")()

export class User extends UserClass {}
```

**When to use**:

- Code in `@package/*` directories
- Will be imported by other packages or applications
- Requires explicit type annotations for better type inference across package boundaries

### Inline Definition (Applications)

Use for application code that won't be used as a package:

```typescript
export class Database extends Context.Tag("@/feature/drizzle/Database")<
  Database,
  () => Client
>() {}
```

**When to use**:

- Code in `@app/*` directories
- Application-specific services
- Won't be imported by other packages

### Identifier Naming Conventions

**Tag identifiers should reflect the file path to avoid collisions**:

Good examples (reflects path structure):

```typescript
"@package/tenant/hono/user/User"
"@package/tenant/hono/db/TenantDatabase"
"@/feature/drizzle/Database"
"@/feature/hono/Context"
```

Bad examples (simple names risk collisions):

```typescript
"User"           // Which User? From which module?
"Database"       // Which Database? App or package?
"Context"        // Too generic
```

**Path-based naming patterns**:

- **For packages**: `@package/{package-name}/{path}/{ClassName}`
  - Example: `@package/tenant/hono/user/User`
- **For applications**: `@/{path}/{ClassName}`
  - Example: `@/feature/drizzle/Database`

**Benefits of path-based naming**:

- Prevents identifier collisions in large projects
- Makes debugging easier (clear error messages)
- Self-documenting (identifier shows the location)
- Enables safe refactoring

## Effect.provide Chaining

Chain Layer provisions with `.pipe()`:

```typescript
const app = createApp.pipe(
  Effect.provide(CloudflareAccess.Middleware.live),
  Effect.provide(CUID.generatorProductionLive),
  Effect.provide(Tenant.DB.make(() => getContext().var.database)),
  Effect.provide(Tenant.DB.live),
  Effect.provide(Tenant.User.live),
  Effect.provide(JWT.User.dev({ id: "test", organizationIDArray: [] })),
  Effect.runSync,
)
```

**Important notes**:

- Chain with `.pipe()`
- Dependency injection order matters (resolved from bottom to top)
- Execute with `Effect.runSync` or `Effect.runPromise` at the end

## Using Effect.runSync

Execute Effect synchronously when appropriate:

```typescript
const userID = makeCUID.pipe(Effect.runSync)
```

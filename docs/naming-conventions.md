# Naming Conventions

This document defines naming conventions for identifiers across the codebase.

## Basic Principles

### Avoid plural forms and use structure-based naming

Always indicate the data structure type explicitly rather than using plural forms:

- **Good**: `userList`, `userArray`, `organizationSet`, `configMap`
- **Bad**: `users`, `organizations`, `configs`

### Assume namespace imports and avoid verbose function names

Function names should be concise because namespace imports provide context:

- **Good**: `Tenant.DB.make()`, `User.live`, `JWT.dev()`
- **Bad**: `makeTenantDatabaseInitializer()`, `devJWTUserLive()`

## Case Styles

Apply consistent case styles based on identifier type:

- **File and directory names**: `kebab-case`
  - Example: `cloudflare-access.ts`, `user-profile/`
- **Database table names**: `snake_case`
  - Example: `cloudflare_access_user`, `organization_table`
- **Variable and function names**: `camelCase`
  - Example: `userArray`, `organizationIDSet`, `makeCUID`
- **Class names**: `PascalCase`
  - Example: `User`, `TenantDatabase`, `ApplicationAudience`
- **Constants and Enums**: `CONSTANT_CASE`
  - Example: `STATUS_CODE`, `API_BASE_URL`, `MAX_RETRY_COUNT`

## Acronyms and Abbreviations

In camelCase/PascalCase, keep acronyms and abbreviations with consistent letter case:

- **Good**: `userID`, `apiURL`, `XMLParser`, `HTTPClient`
- **Bad**: `userId`, `apiUrl`, `XmlParser`, `HttpClient`

## Collection Types

Use appropriate suffixes to indicate collection types:

- **Arrays**: `〜Array` suffix
  - Example: `organizationArray`, `userIDArray`
- **Sets**: `〜Set` suffix
  - Example: `organizationIDSet`, `existIDSet`
- **Maps**: `〜Map` suffix
  - Example: `userMap`, `configMap`
- **Records**: `〜Record` suffix
  - Example: `userRecord`, `dataRecord`

## Function Naming Patterns

### Factory Functions

Choose based on the function's purpose:

- **`make`**: When only generating a value
  - Example: `Tenant.DB.make()`, `Drizzle.make()`
- **`create`**: When including persistence
  - Example: `User.create()`, `Organization.create()`
- **`generate`**: When including side effects (especially randomness)
  - Example: `CUID.generate()`, `Token.generate()`
- **`to`/`from`**: For value conversion (avoid `convert`)
  - Example: `toJSON()`, `fromString()`

### Getter Functions

- Use `get` prefix only when necessary
- Prefer omitting prefix when provided via Context
- Example: Retrieved directly from Context Tag

### Boolean Return Values

Use descriptive prefixes:

- `is〜`: State or type check
  - Example: `isPersonal`, `isValid`
- `has〜`: Possession or availability
  - Example: `hasAccess`, `hasPermission`
- `can〜`: Capability or permission
  - Example: `canEdit`, `canDelete`

## Database-Specific Naming

### Table Variables

Use singular form with `Table` suffix:

- Example: `userTable`, `organizationTable`, `cloudflareAccessUserTable`

### Relation Variables

Append `Relation` suffix to the corresponding table variable name:

- Example: `userRelation`, `cloudflareAccessUserRelation`

See [Database Patterns](./database-patterns.md) for complete database naming guidelines.

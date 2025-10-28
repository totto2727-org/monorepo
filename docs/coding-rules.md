# Coding Standards

This document provides an overview of coding standards for this project.

## Quick Navigation

Each topic has been organized into a dedicated document for easy reference:

1. [Naming Conventions](./naming-conventions.md) - File names, variable names, function names, and more
2. [Import/Export Conventions](./import-export-conventions.md) - Module import/export patterns
3. [TypeScript Conventions](./typescript-conventions.md) - TypeScript-specific rules
4. [Layer Patterns](./layer-patterns.md) - Effect-TS Layer, Context.Tag, dependency injection
5. [Schema Patterns](./schema-patterns.md) - Effect Schema definitions and transformations
6. [Error Handling](./error-handling.md) - HTTPException, Option, and error types
7. [Database Patterns](./database-patterns.md) - Drizzle ORM table definitions and queries

## Overview

### Naming Conventions

Establishes consistent naming patterns across the codebase:

- Avoid plural forms and use structure-based naming (`userArray` vs `users`)
- Assume namespace imports and avoid verbose function names
- Apply consistent case styles: `kebab-case` for files, `camelCase` for variables, `PascalCase` for classes
- Keep acronyms with consistent letter case (`userID` vs `userId`)
- Use appropriate suffixes for collections (`Array`, `Set`, `Map`, `Record`)
- Choose factory function prefixes based on purpose (`make`, `create`, `generate`, `to`/`from`)

See [Naming Conventions](./naming-conventions.md) for complete guidelines.

### Import/Export Conventions

Defines how modules should be imported and exported:

- Use namespace imports for internal code (`@package/*`, `@/`)
- Use named imports for external libraries
- Always use `import type` for type-only imports
- Include `.js` extension for relative imports (ESM compatible)
- Configure `@/` alias in tsconfig for application imports
- Restrict barrel files with explicit reasoning when necessary

See [Import/Export Conventions](./import-export-conventions.md) for complete guidelines.

### TypeScript Conventions

Establishes TypeScript-specific patterns:

- Use `type` by default, `interface` only when necessary (e.g., module augmentation)
- Always use `import type` for type-only imports
- Suppress lint warnings with explicit reasoning when using `interface`

See [TypeScript Conventions](./typescript-conventions.md) for complete guidelines.

### Layer Patterns

Defines patterns for Effect-TS Layer and dependency injection:

- Layer naming: `live` for production, `dev` for development, `test` for testing
- Choose constant or function based on whether parameters are needed
- Context.Tag definition: two-stage for packages, inline for applications
- Tag identifiers should reflect file path to avoid collisions
- Chain Layer provisions with `.pipe()` and `Effect.provide()`

See [Layer Patterns](./layer-patterns.md) for complete guidelines.

### Schema Patterns

Defines patterns for Effect Schema:

- One schema per file (exception: discriminated union variants)
- Always export `make = Schema.decodeSync(schema)`
- Enum patterns with DTO transformation support
- Union types and discriminated unions
- Custom transformations and branded types
- Validation patterns for strings, numbers, and arrays

See [Schema Patterns](./schema-patterns.md) for complete guidelines.

### Error Handling

Establishes error handling patterns:

- Use Hono's `HTTPException` with status code constants
- Utilize Option type for values that may not exist
- Use Predicate utilities for type checking
- Define custom error types using Effect's `TaggedError`

See [Error Handling](./error-handling.md) for complete guidelines.

### Database Patterns

Defines database patterns using Drizzle ORM:

- Table naming: `snake_case` for DB, `camelCase` with `Table` suffix for TS
- Define common columns in separate file for reuse
- Use `cuid2()` for primary keys
- Define relations bidirectionally
- Choose query API for applications, select API for packages
- Integrate with Effect Schema for type safety

See [Database Patterns](./database-patterns.md) for complete guidelines.

## Finding Information

When looking for specific coding guidance:

1. **Start here** to understand the overall structure
2. **Navigate to specific documents** for detailed guidelines
3. **Use document cross-references** to explore related topics
4. **Refer to code examples** in each document for practical implementation

## Contributing to Standards

When proposing changes to coding standards:

1. Update the relevant specific document (not this overview)
2. Ensure changes align with existing patterns
3. Add examples to illustrate the pattern
4. Update cross-references if relationships change

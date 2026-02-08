# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Priority

When working on a project, refer to documentation in the following priority order:

1. **Project-specific docs**: `app/{project}/docs/` - Project-specific implementation details and conventions
2. **CLAUDE.md**: This file - Repository structure, commands, and development guidelines
3. **README.md**: Project overview and setup instructions

## Repository Structure

This is a PNPM monorepo with Turbo for task orchestration.

### Applications

- `app/mcp/` - MCP (Model Context Protocol) server for AI assistant integration
- `app/portal/` - Web application for automatic collection, viewing, and management of RSS and other web information
- `app/rss-graphql/` - GraphQL API server for RSS feed processing and querying

### Packages

- `package/constant/` - Shared constants across packages
- `package/hono-ui/` - Hono JSX UI components
- `package/mcp-oauth-cloudflare-access/` - OAuth middleware for Cloudflare Access integration
- `package/rbac/` - Role-Based Access Control utilities
- `package/tenant/` - Multi-tenant database and authentication utilities
- `package/yamada-ui/` - Yamada UI component library integration

### Infrastructure

- `infra/aws/` - AWS Infrastructure as Code using Pulumi
- `infra/cloudflare/` - Cloudflare Infrastructure configuration using Pulumi

### Documentation

- `docs/coding-rules.md` - Coding standards and conventions
- `docs/ultracite.md` - Lint rules (from Ultracite project)

### Code Analysis and Search

- **serena MCP Priority**: When serena MCP is available, use serena MCP tools for code search and analysis

## Coding Standards

For coding standards in this project, see:

@docs/coding-rules.md

## Lint Rules

For lint rules applied in this project, see:

@docs/ultracite.md

## Development Commands

**Turbo Tasks:**

Use `na -w turbo <task>` to run Turborepo tasks from the root:

- `na -w turbo build` - Build all applications with dependency graph optimization
- `na -w turbo check` - Run type checks across all applications
- `na -w turbo fix` - Auto-fix code with Biome and dprint across all projects

To run tasks from within a specific project directory, use `na turbo <task>` (without `-w`):

- `na turbo build` - Build the current project and its dependencies
- `na turbo check` - Run type checks for the current project
- `na turbo fix` - Auto-fix code with Biome and dprint for the current project

**Note:** Use `@antfu/ni` for package manager-agnostic command execution:

- `na` - Execute commands in workspace context (use with `-w` for root workspace)
- `ni` - Install dependencies (equivalent to `pnpm i`)
- `nr` - Run package scripts (equivalent to `pnpm run`)

## Architecture

### Package Management

- Uses PNPM with catalog mode for centralized dependency version management
- All dependency versions are defined in `pnpm-workspace.yaml` catalog

### Path Aliases

- `@/` - Application internal imports (configured in `tsconfig.json` paths)
- Example: `import * as Drizzle from "@/feature/drizzle.js"`

### Development Tools

- **Turbo**: Monorepo task orchestration (installed via mise)
- **Biome**: Fast linting and formatting
- **dprint**: Additional code formatting

## Documentation Standards

When creating or updating documentation in this repository:

### Length and Structure

- **200 Line Limit**: Keep each document around 200 lines maximum
- **Split When Necessary**: If content exceeds 200 lines, split into multiple focused documents
- **Clear Sections**: Use well-defined sections with descriptive headings
- **Concise Content**: Focus on essential information and avoid redundancy

### Language Requirements

- **All Other Documents**: English

### Content Guidelines

- **No Code Examples**: Avoid including specific code snippets in documentation
- **Conceptual Focus**: Emphasize concepts, patterns, and guidelines
- **Reference Links**: Link to actual code files when specific examples are needed
- **Practical Guidance**: Provide actionable guidance without implementation details

# Ultracite Code Standards

This project uses **Ultracite**, a zero-config preset that enforces strict code quality standards through automated formatting and linting.

## Quick Reference

- **Format code**: `bun x ultracite fix`
- **Check for issues**: `bun x ultracite check`
- **Diagnose setup**: `bun x ultracite doctor`

Oxlint + Oxfmt (the underlying engine) provides robust linting and formatting. Most issues are automatically fixable.

---

## Core Principles

Write code that is **accessible, performant, type-safe, and maintainable**. Focus on clarity and explicit intent over brevity.

### Type Safety & Explicitness

- Use explicit types for function parameters and return values when they enhance clarity
- Prefer `unknown` over `any` when the type is genuinely unknown
- Use const assertions (`as const`) for immutable values and literal types
- Leverage TypeScript's type narrowing instead of type assertions
- Use meaningful variable names instead of magic numbers - extract constants with descriptive names

### Modern JavaScript/TypeScript

- Use arrow functions for callbacks and short functions
- Prefer `for...of` loops over `.forEach()` and indexed `for` loops
- Use optional chaining (`?.`) and nullish coalescing (`??`) for safer property access
- Prefer template literals over string concatenation
- Use destructuring for object and array assignments
- Use `const` by default, `let` only when reassignment is needed, never `var`

### Async & Promises

- Always `await` promises in async functions - don't forget to use the return value
- Use `async/await` syntax instead of promise chains for better readability
- Handle errors appropriately in async code with try-catch blocks
- Don't use async functions as Promise executors

### React & JSX

- Use function components over class components
- Call hooks at the top level only, never conditionally
- Specify all dependencies in hook dependency arrays correctly
- Use the `key` prop for elements in iterables (prefer unique IDs over array indices)
- Nest children between opening and closing tags instead of passing as props
- Don't define components inside other components
- Use semantic HTML and ARIA attributes for accessibility:
  - Provide meaningful alt text for images
  - Use proper heading hierarchy
  - Add labels for form inputs
  - Include keyboard event handlers alongside mouse events
  - Use semantic elements (`<button>`, `<nav>`, etc.) instead of divs with roles

### Error Handling & Debugging

- Remove `console.log`, `debugger`, and `alert` statements from production code
- Throw `Error` objects with descriptive messages, not strings or other values
- Use `try-catch` blocks meaningfully - don't catch errors just to rethrow them
- Prefer early returns over nested conditionals for error cases

### Code Organization

- Keep functions focused and under reasonable cognitive complexity limits
- Extract complex conditions into well-named boolean variables
- Use early returns to reduce nesting
- Prefer simple conditionals over nested ternary operators
- Group related code together and separate concerns

### Security

- Add `rel="noopener"` when using `target="_blank"` on links
- Avoid `dangerouslySetInnerHTML` unless absolutely necessary
- Don't use `eval()` or assign directly to `document.cookie`
- Validate and sanitize user input

### Performance

- Avoid spread syntax in accumulators within loops
- Use top-level regex literals instead of creating them in loops
- Prefer specific imports over namespace imports
- Avoid barrel files (index files that re-export everything)
- Use proper image components (e.g., Next.js `<Image>`) over `<img>` tags

### Framework-Specific Guidance

**Next.js:**

- Use Next.js `<Image>` component for images
- Use `next/head` or App Router metadata API for head elements
- Use Server Components for async data fetching instead of async Client Components

**React 19+:**

- Use ref as a prop instead of `React.forwardRef`

**Solid/Svelte/Vue/Qwik:**

- Use `class` and `for` attributes (not `className` or `htmlFor`)

---

## Testing

- Write assertions inside `it()` or `test()` blocks
- Avoid done callbacks in async tests - use async/await instead
- Don't use `.only` or `.skip` in committed code
- Keep test suites reasonably flat - avoid excessive `describe` nesting

## When Oxlint + Oxfmt Can't Help

Oxlint + Oxfmt's linter will catch most issues automatically. Focus your attention on:

1. **Business logic correctness** - Oxlint + Oxfmt can't validate your algorithms
2. **Meaningful naming** - Use descriptive names for functions, variables, and types
3. **Architecture decisions** - Component structure, data flow, and API design
4. **Edge cases** - Handle boundary conditions and error states
5. **User experience** - Accessibility, performance, and usability considerations
6. **Documentation** - Add comments for complex logic, but prefer self-documenting code

---

Most formatting and common issues are automatically fixed by Oxlint + Oxfmt. Run `bun x ultracite fix` before committing to ensure compliance.

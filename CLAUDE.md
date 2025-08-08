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

- `app/mcp/` - MCP (Model Context Protocol) server application built on Cloudflare Workers + Hono
- `app/lesson-sharing/` - Lesson sharing application

### Documentation

- `docs/` - General documentation and standards

### Code Analysis and Search

- **serena MCP Priority**: When serena MCP is available, use serena MCP tools for code search and analysis

### TypeScript Development

- **typescript-coding-expert Agent**: Use typescript-coding-expert agent for all TypeScript implementation tasks

## Naming Conventions

**Avoid plural forms in file names, directory names, variable names, and table names**

Use structure-based naming instead:
- **Good**: `userList`, `userRecord`, `configMap`, `dataSet`
- **Bad**: `users`, `configs`, `data`

### Case Style Guidelines

- **File and directory names**: Use `kebab-case`
- **Database table names**: Use `snake_case`
- **Variables and classes**: Follow language-specific best practices
  - TypeScript/JavaScript: `camelCase` for variables, `PascalCase` for classes
  - **Constants and Enums**: Use `CONSTANT_CASE`
  - SQL: `snake_case` for columns and identifiers
  - Other languages: Follow their respective conventions

### Acronym and Abbreviation Guidelines

**In camelCase and PascalCase, keep acronyms and abbreviations as consistent letter case**

- **Good**: `userID`, `apiURL`, `XMLParser`, `HTTPClient`
- **Bad**: `userId`, `apiUrl`, `XmlParser`, `HttpClient`

Examples:
- Variables: `userID`, `apiKey`, `xmlData`
- Classes: `APIClient`, `XMLParser`, `HTTPServer`
- Constants: `API_BASE_URL`, `MAX_RETRY_COUNT`

This applies to all naming throughout the project including:
- File and directory names
- Variable and function names
- Database table names
- Type and interface names

## Development Commands

**Turbo Tasks:**

- `turbo build` - Build all applications with dependency graph optimization
- `turbo check` - Run type checks across all applications
- `turbo deploy` - Deploy all applications

**Root Level Tools:**

- `nr check` - Run Biome and dprint checks
- `nr fix` - Auto-fix with Biome and dprint

**Note:** Use `@antfu/ni` for package manager-agnostic command execution:

- Use `na` instead of `pnpm`
- Use `ni` instead of `pnpm i`
- Use `nr` instead of `pnpm run`

## Architecture

### Package Management

- Uses PNPM with catalog mode for centralized dependency version management
- All dependency versions are defined in `pnpm-workspace.yaml` catalog
- Import maps configured with `#@*` prefix for clean internal imports

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

- **CLAUDE.md**: English only (this file)
- **All Other Documents**: Japanese language required
- **Consistency**: Maintain consistent terminology within each document

### Content Guidelines

- **No Code Examples**: Avoid including specific code snippets in documentation
- **Conceptual Focus**: Emphasize concepts, patterns, and guidelines
- **Reference Links**: Link to actual code files when specific examples are needed
- **Practical Guidance**: Provide actionable guidance without implementation details

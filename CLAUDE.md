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

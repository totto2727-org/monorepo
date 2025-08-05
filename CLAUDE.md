# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Priority

When working on a project, refer to documentation in the following priority order:

1. **Project-specific docs**: `app/{project}/docs/` - Project-specific implementation details and conventions
2. **Repository-wide docs**: `docs/` - General standards and patterns applicable across all projects
3. **CLAUDE.md**: This file - Repository structure, commands, and development guidelines
4. **README.md**: Project overview and setup instructions

## Repository Structure

This is a PNPM monorepo with Turbo for task orchestration.

### Applications

- `app/mcp/` - MCP (Model Context Protocol) server application built on Cloudflare Workers + Hono
- `app/lesson-sharing/` - Lesson sharing application

### Documentation

- `docs/coding-standards.md` - Repository-wide TypeScript/React coding standards

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

## Coding Standards

All projects in this monorepo follow consistent coding standards:

For detailed guidelines, see `docs/coding-standards.md`.

## Documentation Standards

When creating or updating documentation in this repository:

### Length and Structure

- **200 Line Limit**: Keep each document around 200 lines maximum
- **Split When Necessary**: If content exceeds 200 lines, split into multiple focused documents
- **Clear Sections**: Use well-defined sections with descriptive headings
- **Concise Content**: Focus on essential information and avoid redundancy

### Language Requirements

- **CLAUDE.md**: English only (this file)
- **Coding Standards**: English only (`docs/coding-standards.md`)
- **All Other Documents**: Japanese language required
- **Consistency**: Maintain consistent terminology within each document

### Content Guidelines

- **No Code Examples**: Avoid including specific code snippets in documentation
- **Conceptual Focus**: Emphasize concepts, patterns, and guidelines
- **Reference Links**: Link to actual code files when specific examples are needed
- **Practical Guidance**: Provide actionable guidance without implementation details

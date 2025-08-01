# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a PNPM monorepo with Turbo for task orchestration.

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

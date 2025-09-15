# Monorepo

A monorepo repository using PNPM and Turbo

## Project Structure

### Applications

- **app/mcp** - MCP (Model Context Protocol) Server
  - Built with Cloudflare Workers + Hono
  - Technical documentation search and AI response generation
  - Currently supports Effect library

- **app/lesson-sharing** - Lesson Sharing Application
  - React Router v7 + Cloudflare Workers
  - Clerk authentication integration
  - Yamada UI components

### Packages

- **package/mcp-oauth-cloudflare-access** - Cloudflare Access OAuth middleware

### Infrastructure

- **infra/aws** - AWS IaC (Pulumi)
- **infra/cloudflare** - Cloudflare IaC (Pulumi)

## Development Setup

### Requirements

- Node.js 24.0.0+
- PNPM 10.0.0+
- mise (for Turbo installation)

### Installation

```bash
# Install dependencies
ni

# Install Turbo (via mise)
mise install
```

## Development Commands

### Global Commands

```bash
# Build all projects
turbo build

# Type checking
turbo check

# Deploy
turbo deploy

# Lint & format check
nr check

# Lint & format auto-fix
nr fix
```

### Project-specific Commands

Run in each project directory:

```bash
# Start development server
nr dev

# Build
nr build

# Deploy
nr deploy
```

## Tech Stack

### Build Tools
- **Turbo** - Monorepo task orchestration
- **Vite** - Build tool
- **TypeScript** - Type safety

### Formatters & Linters
- **Biome** - Fast linting & formatting
- **dprint** - Additional formatting

### Package Management
- **PNPM** - Fast and efficient package manager
- **Catalog Mode** - Centralized dependency version management

## Documentation

- `CLAUDE.md` - Claude Code guidelines
- Each project's `README.md` - Project-specific information
- `app/*/docs/` - Detailed project documentation

## License

Private repository
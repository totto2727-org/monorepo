# Monorepo

A multi-language monorepo (TypeScript + MoonBit) using pnpm workspaces and Vite+.

## Project Structure

### Workspace per Language

- `mbt/`: Moonbit Projects
- `js/`: JavaScript Projects
- `go/`: Go Projects

#### Workspace Structure

- `apps/`: Application projects
- `packages/`: Shared packages

## Development Setup

### Requirements

- `Devbox`: `https://www.jetify.com/docs/devbox/installing-devbox`
- `vite-plus(vp)`: `curl -fsSL https://vite.plus | bash`
- `moonbit`: `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`
- `atlas`: `curl -sSf https://atlasgo.sh | sh`

### Installation

```bash
# Enter development environment
devbox shell

# Install dependencies
vp i
```

## Development Commands

[CLAUDE.md > Development Commands](./CLAUDE.md#development-commands)

## License

Private repository (`@totto2727/fp` is MIT licensed)

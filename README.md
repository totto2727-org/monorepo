# Monorepo

A multi-language monorepo (TypeScript + MoonBit) using Bun workspaces and Vite+.

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

- `Nix`: `https://nixos.org/download/`
- `direnv`: `https://direnv.net/docs/installation.html` (optional)
- `vite-plus(vp)`: `curl -fsSL https://vite.plus | bash`
- `atlas`: `curl -sSf https://atlasgo.sh | sh`

### Installation

```bash
# Enter development environment
nix develop

# Install dependencies
vp i
```

Run `direnv allow` once to load the development environment automatically.

## Development Commands

[CLAUDE.md > Development Commands](./CLAUDE.md#development-commands)

## License

Private repository (`@totto2727/fp` is MIT licensed)

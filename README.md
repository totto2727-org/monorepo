# Monorepo

A multi-language monorepo using Bun workspaces and Vite+.

## Project Structure

### Workspace per Language

- `mbt/`: Moonbit Projects
- `js/`: JavaScript Projects
- `go/`: Go Projects
- `nix/`: Nix Projects
- `elixir/`: Elixir Projects
- `infra/`: Pulumi Projects
- `sandbox/`: Sandbox Config

#### Workspace Structure

- `apps/`: Application projects
- `packages/`: Shared packages

## Development Setup

### Requirements

- `Nix`: `https://nixos.org/download/`
- `atlas`: `curl -sSf https://atlasgo.sh | sh`
- `pulumi`: `brew install pulumi`

### Installation

```bash
# Enter development environment
nix develop

# Install dependencies
vp i
```

Run `direnv allow` once to load the development environment automatically.

## Development Commands

[AGENTS.md > Development Commands](./AGENTS.md#development-commands)

## License

Private repository (`@totto2727/monorepo` is MIT licensed)

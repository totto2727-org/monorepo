# Monorepo

A multi-language monorepo using Bun workspaces and Vite+.

## Project Structure

### Workspace per Language

- `js/`: JavaScript Projects
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

## Dependency Policy

Dependency updates stay within compatible manifest and catalog ranges by default. Do not use release-age exclusions or general dependency overrides to force a newer release to install.

- Preserve the package manager's default release-age behavior and the existing registry configuration. Bun's default minimum release age is zero when no age gate is configured. This repository does not configure an age gate, lower an existing one, or add exclusions. [Bun's optional age gate](https://bun.com/docs/pm/cli/install#minimum-release-age) is not enabled by default, and its documentation's three-day example is not a default policy. Do not confuse this with another package manager's defaults.
- Use the latest compatible installable release through the existing registry and review publication dates when refreshing the lockfile. Do not force a release through by changing security settings, adding arbitrary waiting periods, or adding automatic exclusions.
- The `vite` core alias and exact bundled `vitest` override are the only dependency override exceptions, as required by [Vite+ manual installation](https://viteplus.dev/guide/local-cli#manual-installation). Keep them aligned when [upgrading Vite+](https://viteplus.dev/guide/upgrade-project#updating-the-vitest-pin). The coverage provider must also match the bundled Vitest version because it declares an exact Vitest peer.
- Remix remains a direct `remix` dependency with a caret beta range. The upper bound excludes beta.3 and later because their UI renderer no longer accepts the existing render-function props API. Later beta releases also remove the existing `Button` component API. Do not replace this with an `@remix-run/ui` dependency or migrate application JSX as part of a routine dependency update.
- Better Auth stays below 1.7 while the application uses the 1.6 generic OAuth API (`issuer` and `signInWithOAuth2`). Prefer a compatible catalog range over an override or an unrelated source migration.

## License

Private repository (`@totto2727/monorepo` is MIT licensed)

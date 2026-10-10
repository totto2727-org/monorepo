# Monorepo

A multi-language monorepo using Node.js, pnpm workspaces, and Vite+.

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
vp install --frozen-lockfile
```

Run `direnv allow` once to load the development environment automatically.

## Development Commands

[AGENTS.md > Development Commands](./AGENTS.md#development-commands)

## Dependency Policy

Dependency updates stay within compatible manifest and catalog ranges by default. Do not use release-age exclusions or general dependency overrides to force a newer release to install.

- pnpm is the sole repository package manager, pinned to `11.21.0` in `package.json` and supplied by the existing root Nix input. Vite+ remains unchanged and dispatches `vp install` to pnpm. Workspace membership and catalogs live in `pnpm-workspace.yaml`, and `pnpm-lock.yaml` is the only repository dependency lockfile.
- Preserve the existing registry configuration and [pnpm's release-age safeguards](https://pnpm.io/settings#minimumreleaseage): `minimumReleaseAge: 1440` and `minimumReleaseAgeStrict: true` enforce a 24-hour wait and reject missing publication timestamps. Do not lower the gate or add exclusions.
- Use compatible caret ranges and the latest compatible mature release through the existing registry when deliberately refreshing the lockfile with `vp install --no-frozen-lockfile`. Use `vp install --frozen-lockfile` for reproducible local and CI installs. Do not force a release through by changing security settings or adding automatic exclusions.
- The `vite` core alias and exact bundled `vitest` override are the only dependency override exceptions, as required by [Vite+ manual installation](https://viteplus.dev/guide/local-cli#manual-installation). Keep them aligned when [upgrading Vite+](https://viteplus.dev/guide/upgrade-project#updating-the-vitest-pin). The coverage provider must also match the bundled Vitest version because it declares an exact Vitest peer.
- Remix remains a direct `remix` dependency with a caret beta range. The upper bound excludes beta.3 and later because their UI renderer no longer accepts the existing render-function props API. Later beta releases also remove the existing `Button` component API. Do not replace this with an `@remix-run/ui` dependency or migrate application JSX as part of a routine dependency update.
- Better Auth stays below 1.7 while the application uses the 1.6 generic OAuth API (`issuer` and `signInWithOAuth2`). Prefer a compatible catalog range over an override or an unrelated source migration.
- Lifecycle scripts are allowed only for the previously trusted `esbuild`, `msgpackr-extract`, `sharp`, and `workerd` packages, via pnpm's `allowBuilds` configuration. The previously untrusted `protobufjs` postinstall remains explicitly denied so pnpm can complete non-interactively without widening permissions. Review any new build-script requirement instead of automatically approving it.
- The old Bun patch registration for `@better-auth/kysely-adapter@1.6.12` was already inactive with the resolved `1.6.33` dependency and is not carried into pnpm configuration. The patch file remains available for historical reference.

### Bun Runtime Scope

Node.js is the default JavaScript runtime. Bun remains in the development shell because `infra/aws/Pulumi.yaml` and `infra/cloudflare/Pulumi.yaml` select it to execute TypeScript directly. These projects still install dependencies through pnpm via Vite+. Shared global-tool wrappers and system runtime installations under `nix/` are separate from repository dependency management and are not migrated by this change. Historical ADRs and runtime compatibility examples may still mention Bun.

## License

Private repository (`@totto2727/monorepo` is MIT licensed)

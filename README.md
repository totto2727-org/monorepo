# Monorepo

A multi-language monorepo using Node.js, pnpm workspaces, and Vite+.

## Project Structure

### Workspace per Language

- `js/`: JavaScript Projects
- `nix/`: Nix Projects, including [local CLI packages](./nix/share/packages/README.md)
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
- Preserve the existing registry configuration and [pnpm's release-age safeguards](https://pnpm.io/settings#minimumreleaseage). pnpm 11 defaults to a 24-hour wait, so no `minimumReleaseAge` setting is needed. Keep `minimumReleaseAgeStrict: true` to reject unapproved immature versions in non-interactive installs. Do not lower the gate or add exclusions.
- Use compatible caret ranges and the latest compatible mature release through the existing registry when deliberately refreshing the lockfile with `vp install --no-frozen-lockfile`. Use `vp install --frozen-lockfile` for reproducible local and CI installs. Do not force a release through by changing security settings or adding automatic exclusions.
- The `vite` core alias and exact bundled `vitest` override are the only dependency override exceptions, as required by [Vite+ manual installation](https://viteplus.dev/guide/local-cli#manual-installation). Use the official pnpm-managed keys `vite@*` and `vitest@*` so overrides do not rewrite `catalog:` references. Keep them aligned when [upgrading Vite+](https://viteplus.dev/guide/upgrade-project#updating-the-vitest-pin). The coverage provider must also match the bundled Vitest version because it declares an exact Vitest peer.
- Remix uses the stable `^3.0.0` range. Components and JSX import from `remix/component`, read props through `handle.props`, and use native buttons with application-owned styles. See the [official rendering guide](https://github.com/remix-run/remix/blob/main/packages/remix/guides/04-rendering-ui.md).
- Better Auth and its OAuth provider and passkey plugins use `^1.7.7`. The generic OAuth integration uses `signInSocial`, OIDC discovery with required ID-token verification, and `/api/v1/auth/callback/identity-provider`. Follow the [official 1.7 upgrade guide](https://www.better-auth.com/docs/guides/1-7-upgrade-guide) and update registered client redirect URIs when upgrading an existing environment.
- Type checking runs through `vp check` in the root `js:check` task, not a separate TypeScript CLI command. The unused TypeScript CLI catalog and `@typescript/native-preview` are removed. Only `vite-plugin-mdts` uses the `compiler-api` catalog (`^6.0.3`) because its parser requires the legacy `createSourceFile` compiler API, which TypeScript 7 no longer exports from `typescript`. The [published TypeScript package metadata](https://registry.npmjs.org/typescript/7.0.2) lists separate `unstable/*` API entry points. Keep that compatibility dependency local to the Markdown compiler rather than rewriting its parser during a library update.
- Lifecycle scripts are allowed only for the previously trusted `esbuild`, `msgpackr-extract`, `sharp`, and `workerd` packages, via pnpm's `allowBuilds` configuration. The previously untrusted `protobufjs` postinstall remains explicitly denied so pnpm can complete non-interactively without widening permissions. Review any new build-script requirement instead of automatically approving it.
- The old Bun patch registration for `@better-auth/kysely-adapter@1.6.12` was already inactive with the resolved `1.6.33` dependency and is not carried into pnpm configuration. The patch file remains available for historical reference.

### Bun Runtime Scope

Node.js is the default JavaScript runtime. Bun remains in the development shell because `infra/aws/Pulumi.yaml` and `infra/cloudflare/Pulumi.yaml` select it to execute TypeScript directly. These projects still install dependencies through pnpm via Vite+. Shared global-tool wrappers and system runtime installations under `nix/` are separate from repository dependency management and are not migrated by this change. Historical ADRs and runtime compatibility examples may still mention Bun.

## License

Private repository (`@totto2727/monorepo` is MIT licensed)

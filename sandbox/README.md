# Sandbox images

This guide is for contributors who build sandbox images and developers who extend them with a gateway.
It assumes familiarity with OCI images and Nix flakes.

The sandbox is a reusable, non-root coding environment for local OCI containers and Cloudflare Container-derived applications.
It does not start an HTTP gateway or manage task lifecycles.

## Image layers

| Image              | Contents                                                                                       | Default entrypoint              |
| ------------------ | ---------------------------------------------------------------------------------------------- | ------------------------------- |
| `sandbox-base`     | Ubuntu 26.04, network tools, Git, a single-user Nix installation, and Jcode                    | `/bin/bash`                     |
| `sandbox-dev`      | Base plus the sandbox Home Manager configuration, Node.js 24, pnpm, Vite+, and public dotfiles | `/sandbox/.nix-profile/bin/zsh` |
| `sandbox-monorepo` | Dev plus a monorepo checkout and OpenShell policy                                              | Inherited Zsh                   |

Jcode is installed in the base image with the [official installer](https://jcode.sh/install), not a Nix overlay.
Pass `--build-arg JCODE_VERSION=vX.Y.Z` to the base build to select a release.
Without this argument, the official installer selects its latest stable release.
The installer verifies release checksums.
Nix and the installer script are fetched at build time, so pinning Jcode alone does not make the whole image bit-for-bit reproducible.

The dev build copies `nix/share`, `nix/npm-package`, and `nix/sandbox` from its build context.
It does not fetch a different revision of the sandbox configuration from the default branch.
Its Dockerfile-specific ignore file permits only these inputs and excludes workstation configuration, including `nix/macos`.
The pinned sandbox nixpkgs does not provide `gh-stack` or `witr`, so the sandbox omits that GitHub extension and includes `witr` only when available.

The shared Monid and oo CLI packages compile as ESM without Bun bytecode.
The pinned Bun version cannot combine `--format=esm` with `--bytecode`.
This compilation setting applies to every consumer of `nix/share/packages`, including macOS, but does not change package versions or the standalone executable format.
The sandbox Vite+ wrapper uses Node.js 24, so task commands and the interactive `node` command use the same major version.
The dev build collects unreferenced Nix build dependencies before exporting its layer.

## Build from the repository root

Build the layers in order with Apple container on Apple Silicon:

```bash
just --justfile sandbox/Justfile docker-build-sandbox-base
just --justfile sandbox/Justfile docker-build-sandbox-dev
just --justfile sandbox/Justfile docker-build-sandbox-monorepo
```

Use Docker and `linux/amd64` for a Cloudflare-compatible base:

```bash
SANDBOX_CONTAINER_RUNTIME=docker just --justfile sandbox/Justfile docker-build-sandbox-base linux/amd64
```

The GitHub deployment workflow builds both `linux/amd64` and `linux/arm64`.
The base and monorepo Dockerfiles use `sandbox` as their context.
The dev Dockerfile uses the repository root as its context.
To select another base image for a dev build, pass `--build-arg SANDBOX_BASE_IMAGE=<image>` directly to the build command.
The root `Justfile` also provides the ordered Docker build workflow.

## Validate

Evaluate both Linux configurations before building the dev image:

```bash
nix eval ./nix/sandbox#homeConfigurations.sandbox-aarch64-linux.activationPackage.drvPath --raw
nix eval ./nix/sandbox#homeConfigurations.sandbox-x86_64-linux.activationPackage.drvPath --raw
```

After building the base, check its non-interactive runtime contract:

```bash
container run --rm --entrypoint /bin/bash ghcr.io/totto2727-org/monorepo/sandbox-base:latest -euc 'test "$(id -un)" = sandbox; test "$HOME" = /sandbox; test -w "$HOME"; test -w /nix; jcode --version; nix --version; jcode api-bridge --help >/dev/null'
```

Replace `container` with `docker` to run the same check with Docker.
For the dev image, also check `node --version`, `pnpm --version`, and `vp --version`.
Home Manager makes the Zsh startup files read-only.
Vite+ can warn when its first-run setup tries to update those shell profiles, but its CLI and task runner work through the image's configured `PATH`.
Do not change Nix store permissions to suppress this warning.
These checks do not verify provider authentication or an end-to-end coding task.

## Application integration contract

- The runtime user and group are `sandbox`, with writable home directory `/sandbox`.
- `HOME=/sandbox` and `USER=sandbox` are set for non-interactive processes.
- `PATH` contains `/sandbox/.local/bin` and `/sandbox/.nix-profile/bin`.
- The Jcode launcher is `/sandbox/.local/bin/jcode`.
- A gateway derived from `sandbox-base` must supply a Node runtime.
- A gateway derived from `sandbox-dev` can use its provided Node.js 24 runtime and Vite+ toolchain.
- Every gateway must supply its own command and listening port.
- The base supplies `libstdc++6` for a derived Node runtime.
- A gateway may spawn Jcode's Unix-socket API bridge as the sandbox user and keep its socket private to that container.
- The application owns gateway authentication and the bridge protocol.

Keep the same container, workspace, and Jcode session until the coding task is complete.
Do not recreate the container after each prompt or clear `/sandbox/.jcode` between calls.
The application decides when a task is complete and when to remove its container.
Use an explicit workspace volume if state must survive container replacement.

Never put provider credentials or workstation Jcode authentication files in a Dockerfile, build argument, or build context.
Supply credentials at runtime through the platform's secret mechanism or an explicitly scoped mount.
The sandbox context excludes `secrets/` and `.env` files.
No credentials are necessary to build the image or run `jcode --version`.

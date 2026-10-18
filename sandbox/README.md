# Sandbox images

This guide is for contributors who build sandbox images and developers who extend them with a gateway.
It assumes familiarity with OCI images and Nix flakes.

The sandbox is a reusable, non-root coding environment for local OCI containers and Cloudflare Container-derived applications.
It does not start an HTTP gateway or manage task lifecycles.

## Image layers

| Image              | Contents                                                             | Default entrypoint                   |
| ------------------ | -------------------------------------------------------------------- | ------------------------------------ |
| `sandbox-base`     | Ubuntu 26.04, network tools, Git, and a single-user Nix installation | `/bin/bash`                          |
| `sandbox-dev`      | Base plus the sandbox Home Manager configuration and public dotfiles | `/home/sandbox/.nix-profile/bin/zsh` |
| `sandbox-monorepo` | Dev plus a monorepo checkout and OpenShell policy                    | Inherited Zsh                        |

Workflow-specific applications, runtimes, and libraries belong to derived images, not these generic sandbox layers.
For example, a Jcode workflow image installs Jcode and its gateway runtime itself.
The Nix installer is fetched at build time, so the base image is not bit-for-bit reproducible.

The dev build copies `nix/share`, `nix/npm-package`, and `nix/sandbox` from its build context.
It does not fetch a different revision of the sandbox configuration from the default branch.
Its Dockerfile-specific ignore file permits only these inputs and excludes workstation configuration, including `nix/macos`.
Each sandbox flake input keeps its own dependency pins, as in the macOS configuration.
Do not add `follows` overrides unless a demonstrated compatibility requirement needs them.
The sandbox uses the same nixpkgs release series as macOS and installs the shared `witr` package and GitHub extensions without conditional omissions.
Language runtimes and project tools belong to each target repository's `devShell`, not the sandbox Home Manager profile.

The dev build collects unreferenced Nix build dependencies before exporting its layer.

## Build from the repository root

Build the layers in order with Apple container:

```bash
just --justfile sandbox/Justfile docker-build-sandbox-base
just --justfile sandbox/Justfile docker-build-sandbox-dev
just --justfile sandbox/Justfile docker-build-sandbox-monorepo
```

Local recipes do not select an architecture; the container runtime uses its native default.
Use the root `Justfile` for the ordered Docker build workflow.

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
container run --rm --entrypoint /bin/bash ghcr.io/totto2727-org/monorepo/sandbox-base:latest -euc 'test "$(id -un)" = sandbox; test "$HOME" = /home/sandbox; test -w "$HOME"; test -w /nix; nix --version'
```

Replace `container` with `docker` to run the same check with Docker.
For the dev image, check the default Zsh and shared CLI tools.
Enter the target repository's development shell with `nix develop` before checking its language runtimes and task runner.
These checks do not verify provider authentication or an end-to-end coding task.

## Application integration contract

- The runtime user and group are `sandbox`, with writable home directory `/home/sandbox`.
- `HOME=/home/sandbox` and `USER=sandbox` are set for non-interactive processes.
- `PATH` contains `/home/sandbox/.local/bin` and `/home/sandbox/.nix-profile/bin`.
- A gateway derived from either image must supply its own runtime; the sandbox does not preinstall Node.js or Vite+.
- Every gateway must supply its own command and listening port.
- A derived image installs any runtime libraries its applications need.
- The application owns gateway authentication and any agent bridge protocol.

Keep the same container and workspace until the coding task is complete.
The workflow owns any agent session and its configuration directory.
The application decides when a task is complete and when to remove its container.
Use an explicit workspace volume if state must survive container replacement.

Never put provider credentials or workstation Jcode authentication files in a Dockerfile, build argument, or build context.
Supply credentials at runtime through the platform's secret mechanism or an explicitly scoped mount.
The sandbox context excludes `secrets/` and `.env` files.
No provider credentials are necessary to build these generic images.

# Sandbox images

This guide is for contributors who build sandbox images and developers who extend them with a gateway.
It assumes familiarity with OCI images and Nix flakes.

The sandbox is a reusable, non-root coding environment for container-based agent workflows.
It does not start an HTTP gateway or manage task lifecycles.

## Image layers

| Image              | Contents                                                             | Default entrypoint |
| ------------------ | -------------------------------------------------------------------- | ------------------ |
| `sandbox-base`     | Ubuntu 26.04, network tools, Git, and a single-user Nix installation | `/bin/bash`        |
| `sandbox-dev`      | Base plus the sandbox Home Manager configuration                     | `/bin/bash`        |
| `sandbox-monorepo` | Dev plus a monorepo checkout and OpenShell policy                    | Inherited Bash     |

Workflow-specific applications, runtimes, and libraries belong to derived images, not these generic sandbox layers.
For example, a Jcode workflow image installs Jcode and its gateway runtime itself.
The Nix installer is fetched at build time, so the base image is not bit-for-bit reproducible.

The dev build copies `nix/share` and `nix/sandbox` from its build context.
It does not fetch a different revision of the sandbox configuration from the default branch.
Its Dockerfile-specific ignore file permits only these inputs and excludes workstation configuration, including `nix/macos`.
Each sandbox flake input keeps its own dependency pins, as in the macOS configuration.
Do not add `follows` overrides unless a demonstrated compatibility requirement needs them.
The sandbox uses the same nixpkgs release series as macOS, but defines its own package list directly in `nix/sandbox/flake.nix` instead of importing the shared base or development package lists.
It keeps Git, ripgrep, sd, fd, nixfmt, and Just for agent workflows, plus Home Manager, direnv, and GitHub CLI.
All layers use `/bin/bash`; the sandbox does not install Zsh or define a Home Manager shell alias.
To update the profile, pass `--flake ~/nix/sandbox#sandbox-<system>` explicitly to `home-manager switch`.
It does not install chezmoi or apply personal dotfiles.
The shared sandbox scripts list still provides Monid, oo, and the Docker credential helper.
Interactive editors, file managers, fuzzy finders, process viewers, shell prompt/navigation plugins, GitHub extensions, and the `wt` and `j` wrappers are not installed.
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
For the dev image, check the default Bash and shared CLI tools.
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

## Runtime provider environment

This section is for developers who configure a derived application or its task launcher.
Supply these variables to the agent process at runtime.
Use these names rather than generic names such as `API_KEY` or `BASE_URL`.
Each workflow needs only the credentials for the services it uses.

| Variable                        | Value                                                                              | Secret |
| ------------------------------- | ---------------------------------------------------------------------------------- | ------ |
| `OPENCONNECTOR_BASE_URL`        | Trusted HTTPS OOMOL/OpenConnector gateway origin, without `/v1` or a provider path | No     |
| `OPENCONNECTOR_TOKEN`           | Runtime token authorized for that gateway                                          | Yes    |
| `CLOUDFLARE_ACCOUNT_ID`         | Cloudflare account ID for inference                                                | No     |
| `CLOUDFLARE_AI_GATEWAY_ID`      | Existing AI Gateway ID within that account                                         | No     |
| `CLOUDFLARE_AI_GATEWAY_API_KEY` | Cloudflare token authorized for the selected inference route                       | Yes    |

### OOMOL, oo, and Monid

`OPENCONNECTOR_BASE_URL` and `OPENCONNECTOR_TOKEN` are the shared inputs used by the OpenConnector and Monid skills.
The [macOS wrappers](../nix/share/packages-scripts.nix) use the same names, but obtain their values from the workstation password manager.
The sandbox installs the `oo` and `monid` binaries without those macOS wrappers.
It does not read workstation secrets or create CLI profiles.
The application must map the shared inputs before it starts the agent:

```bash
export OO_CONNECTOR_URL="$OPENCONNECTOR_BASE_URL"
export OO_CONNECTOR_TOKEN="$OPENCONNECTOR_TOKEN"
export MONID_API_BASE_URL="${OPENCONNECTOR_BASE_URL%/}/v1/passthrough/monid"
```

| CLI setting                      | Source                                      | Purpose                                            |
| -------------------------------- | ------------------------------------------- | -------------------------------------------------- |
| `OO_CONNECTOR_URL`               | `OPENCONNECTOR_BASE_URL`                    | Select the trusted Connector gateway               |
| `OO_CONNECTOR_TOKEN`             | `OPENCONNECTOR_TOKEN`                       | Authenticate `oo` Connector requests               |
| `MONID_API_BASE_URL`             | Gateway origin plus `/v1/passthrough/monid` | Send Monid requests through the same gateway       |
| Monid profile `active_key`       | `gateway`                                   | Select the gateway credential profile              |
| Monid profile `keys.gateway.key` | `OPENCONNECTOR_TOKEN`                       | Authenticate Monid requests with the runtime token |

`MONID_API_BASE_URL` selects the endpoint, but does not configure Monid authentication by itself.
Before invoking Monid, the application must create a private profile under `${XDG_CONFIG_HOME:-$HOME/.config}/monid` as described by the `monid` skill.
The existing macOS Monid wrapper illustrates a temporary profile with `umask 077`, `config.yaml`, and `credentials.yaml`.
Keep the profile within the task lifecycle and remove temporary credentials when the task ends.
Do not use a direct Monid key or its default public endpoint for this environment.

These settings configure Connector and Monid access, not the OOMOL-hosted LLM API.
For that separate API, follow the `oo` skill and obtain client settings with `oo llm config --json` in an authorized OOMOL account context.
Do not assume the Connector origin is an OpenAI-compatible base URL.

### Cloudflare AI

Follow the `cloudflare-ai` skill for request bodies, model selection, and authentication.
It uses the fixed Cloudflare hosts below, so no additional Cloudflare URL variable is required.
These shell assignments construct endpoints without making a request:

```bash
CLOUDFLARE_CHAT_COMPLETIONS_URL="https://gateway.ai.cloudflare.com/v1/${CLOUDFLARE_ACCOUNT_ID}/${CLOUDFLARE_AI_GATEWAY_ID}/compat/chat/completions"
CLOUDFLARE_WORKERS_AI_RUN_URL="https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/ai/run"
```

The URL variable names above are local examples, not additional inputs required by the skill.
The compatibility endpoint uses `cf-aig-authorization: Bearer <token>`.
Workers AI uses `Authorization: Bearer <token>` and selects the Gateway with `cf-aig-gateway-id: <gateway-id>` when the skill requires it.
In both cases, `<token>` comes from `CLOUDFLARE_AI_GATEWAY_API_KEY`.
Gateway access and Workers AI inference require different permissions.
The variable name does not prove that a token has both permissions, and an inference token must not be treated as a deployment credential.

See [AI Gateway REST API](https://developers.cloudflare.com/ai-gateway/usage/rest-api/) and [Workers AI REST setup](https://developers.cloudflare.com/workers-ai/get-started/rest-api/) for the provider contracts.

### Secret handling

Use the platform's runtime secret injection for both tokens.
Do not persist tokens in the image, Nix store, repository, shell startup files, or task logs.
Do not print environment values, enable shell tracing, or pass tokens as literal command arguments.
For curl requests, follow the skill's stdin configuration pattern rather than placing authentication headers in command arguments.
Pass the variables only to processes that need them.
The launcher owns environment mapping and Monid profile setup; this README does not add automatic startup behavior to the image.

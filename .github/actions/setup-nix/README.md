# Setup Nix

Install Determinate Nix, enable Magic Nix Cache, configure an optional binary cache, and prepare a development shell.
This guide serves action users who maintain GitHub workflows.
The cache helper uses Python 3 and its standard library only.
It does not need Node.js, Vite+, workspace dependencies, or a development shell.
GitHub-hosted Linux and macOS runners provide Python 3.

## Usage

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
- uses: ./.github/actions/setup-nix
  with:
    cache-url: ${{ vars.NIX_CACHE_URL }}
    cache-public-key: ${{ vars.NIX_CACHE_PUBLIC_KEY }}
    cache-username: ${{ secrets.NIX_CACHE_USERNAME }}
    cache-password: ${{ secrets.NIX_CACHE_PASSWORD }}
    prepare-dev-shell: 'false'
```

| Input               | Default   | Purpose                                                                                              |
| ------------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| `cache-url`         | Empty     | HTTPS binary cache URL. Required when any cache input is set.                                        |
| `cache-public-key`  | Empty     | Signing public key, normally `name:base64`. Required with `cache-url`. Nix validates the key format. |
| `cache-username`    | Empty     | HTTP Basic authentication username. Requires `cache-password`.                                       |
| `cache-password`    | Empty     | HTTP Basic authentication password. Requires `cache-username`. Use a GitHub secret.                  |
| `prepare-dev-shell` | `'true'`  | Run `nix develop` after cache configuration.                                                         |
| `dev-shell`         | `default` | Development shell attribute to prepare.                                                              |

Leave all four cache inputs empty to retain the previous behavior.
For a public cache, set only the URL and public key.
Partial inputs fail before configuration writes.
The helper rejects line breaks because it writes line-oriented configuration files.
Nix validates cache URLs and signing keys when it uses them.
For authentication, the URL must have a hostname to select the netrc entry.
Netrc values are quoted and escaped, so credentials can contain spaces, double quotes, backslashes, and `#`.
HTTP Basic authentication uses `:` as its username separator, so use a username without `:`.

## Configuration and runtime requirements

The action runs cache configuration **after Magic Nix Cache and before development-shell preparation**.
It appends `extra-substituters` and `extra-trusted-public-keys` to the user's `nix.conf`.
It does not replace system settings, public caches, trusted keys, or signature requirements.
The default path is `$XDG_CONFIG_HOME/nix/nix.conf`, or `$HOME/.config/nix/nix.conf` when `XDG_CONFIG_HOME` is empty or unset.
When `NIX_USER_CONF_FILES` is set, the helper appends to the last file in its colon-separated list instead.
The target must be writable.
Use configuration paths that Nix reads in the same environment.
Do not override these settings later through `NIX_CONFIG`, command-line options, or replacement configuration files.

Authenticated caches also set `netrc-file` to a file created exclusively with mode `0600` inside a unique mode-`0700` directory under `RUNNER_TEMP`.
This replaces the effective netrc path and does not merge credentials from an existing netrc file.
Use this automatic authentication setup on runners that do not need other netrc credentials for Nix.
The netrc machine is the URL hostname without its port or IPv6 brackets.
Authentication is hostname-scoped, not path-scoped.
Use a dedicated cache hostname if other endpoints on that host must not receive these credentials.
The helper removes only its own temporary directory if configuration fails.
Successful credentials remain available to subsequent Nix commands until runner cleanup.
Self-hosted runners must clean their job temporary directories after use.
The helper reports generic errors without printing input values or exception details.

For a multi-user Nix installation, the runner must be a **trusted daemon client** and the daemon must be able to read the generated netrc file.
The pinned Determinate installer defaults to `trust-runner-user: true` for a fresh installation.
On standard hosted runners, the root daemon can read the runner-owned private file.
The helper does not probe daemon trust or cache availability.
Nix applies its own trust and configuration rules when subsequent commands use the cache.
An existing self-hosted installation is not automatically repaired or granted trust by this helper.
An untrusted daemon client cannot rely on user configuration to authorize a new substituter or signing key.
Configure runner trust through the runner administrator before using this action in that environment.
The action never edits `/etc/nix` or restarts a daemon.

Nix sends modified client settings through `RemoteStore::setOptions` and applies them for trusted clients in the daemon.
See the [Nix 2.33.3 remote store implementation](https://github.com/NixOS/nix/blob/2.33.3/src/libstore/remote-store.cc) and [daemon implementation](https://github.com/NixOS/nix/blob/2.33.3/src/libstore/daemon.cc).
See also the [Nix configuration reference](https://nix.dev/manual/nix/2.33/command-ref/conf-file) and the [pinned Determinate action](https://github.com/DeterminateSystems/determinate-nix-action/blob/2a0be2498974c2b6327e19780488744384637d88/action.yml).

## CI

The focused `setup-nix.yaml` workflow runs the shared action and checks its effective configuration on native Linux amd64, Linux arm64, and macOS runners.
The fixture cache is not contacted, and these checks do not establish authenticated remote substitution or cache availability.

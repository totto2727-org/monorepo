# Local Nix packages

| Package         | Definition     | Dependency lock            |
| --------------- | -------------- | -------------------------- |
| `monid`         | `monid.nix`    | Generated `monid-bun.nix`  |
| `oo-cli` (`oo`) | `oo-cli.nix`   | Generated `oo-cli-bun.nix` |
| `pass-cli`      | `pass-cli.nix` | `vendorHash`               |

Run commands from the repository root.

## monid

### Update

Update `version` and the source hash in `monid.nix`, then regenerate dependencies:

```bash
source=$(nix build ./nix/share/packages#monid.src --no-link --print-out-paths)
nix run ./nix/share/packages#bun2nix -- \
  --lock-file "$source/bun.lock" \
  --output-file nix/share/packages/monid-bun.nix
```

### Validate

```bash
nix build ./nix/share/packages#monid --no-link
nix run ./nix/share/packages#monid -- --version
nix run ./nix/share/packages#monid -- --help
```

## oo-cli

### Update

Update `version` and the source hash in `oo-cli.nix`, then regenerate dependencies:

```bash
source=$(nix build ./nix/share/packages#oo-cli.src --no-link --print-out-paths)
nix run ./nix/share/packages#bun2nix -- \
  --lock-file "$source/bun.lock" \
  --output-file nix/share/packages/oo-cli-bun.nix
```

### Validate

```bash
nix build ./nix/share/packages#oo-cli --no-link
nix run ./nix/share/packages#oo-cli -- version --json
nix run ./nix/share/packages#oo-cli -- --help
nix run ./nix/share/packages#oo-cli -- skills info --source bundled --json
```

## pass-cli

### Update

Update `version`, `rev`, and hashes in `pass-cli.nix`.
Set changed hashes to `lib.fakeHash`, build, and use the reported hashes.

### Validate

```bash
nix build ./nix/share/packages#pass-cli --no-link
nix run ./nix/share/packages#pass-cli -- version
```

## Shared checks

```bash
vp run --filter @app/nix fix
vp run --filter @app/nix check
nix flake check ./nix/share/packages --all-systems --no-build
```

Builds run on the current system; `--all-systems --no-build` only evaluates other systems.

### Native CI smoke tests

The [shared-tools workflow](../../../.github/workflows/nix-shared-tools.yaml) builds `pass-cli`, `monid`, and `oo-cli` on native `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin` runners.
It checks `builtins.currentSystem` before building each package with `--no-link --print-out-paths`.
It runs `pass-cli version`, `monid --version`, and `oo --version` from the resulting store paths with isolated home directories and no inherited credentials.
The same jobs use the official `voidzero-dev/setup-vp` action with `run-install: false`, then run `vp env install`, `vp --version`, and `vp exec node --version`.
Vite+ and Node.js are not Nix packages in this workflow, and workspace dependencies are not installed.
Run the workflow manually with `workflow_dispatch`, or trigger it through a pull request that changes the workflow's watched paths.
The native workflow has not yet been executed remotely, so these definitions are not evidence of successful builds on all three platforms.

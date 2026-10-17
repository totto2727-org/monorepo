# Local Nix packages

| Package         | Definition     | Dependency lock            |
| --------------- | -------------- | -------------------------- |
| `oo-cli` (`oo`) | `oo-cli.nix`   | Generated `oo-cli-bun.nix` |
| `pass-cli`      | `pass-cli.nix` | `vendorHash`               |

Run commands from the repository root.

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

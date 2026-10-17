# Local Nix packages

| Package         | Definition     | Dependency lock            |
| --------------- | -------------- | -------------------------- |
| `oo-cli` (`oo`) | `oo-cli.nix`   | Generated `oo-cli-bun.nix` |
| `pass-cli`      | `pass-cli.nix` | `vendorHash`               |

## Update

Run from the repository root after updating the package definition.
For oo-cli, regenerate its dependency file:

```bash
source=$(nix build ./nix/share/packages#oo-cli.src --no-link --print-out-paths)
nix run ./nix/share/packages#bun2nix -- \
  --lock-file "$source/bun.lock" \
  --output-file nix/share/packages/oo-cli-bun.nix
```

For pass-cli, set changed hashes to `lib.fakeHash`, build, and use the reported hashes.

## Validate

```bash
vp run --filter @app/nix fix
vp run --filter @app/nix check
nix flake check ./nix/share/packages --all-systems --no-build
nix build ./nix/share/packages#oo-cli ./nix/share/packages#pass-cli --no-link
nix run ./nix/share/packages#oo-cli -- version --json
nix run ./nix/share/packages#oo-cli -- --help
nix run ./nix/share/packages#oo-cli -- skills info --source bundled --json
nix run ./nix/share/packages#pass-cli -- version
```

Builds run on the current system; `--all-systems --no-build` only evaluates other systems.

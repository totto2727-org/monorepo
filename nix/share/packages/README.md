# Local Nix packages

This catalog serves users who select local packages and maintainers who update their build definitions.
Run the commands below from the repository root.

## Build and run oo-cli

```bash
nix build ./nix/share/packages#oo-cli
./result/bin/oo --version
nix run ./nix/share/packages#oo-cli -- --help
```

The package builds [oo-cli v1.9.8](https://github.com/oomol-lab/oo-cli/tree/v1.9.8) from source with `bun build --compile`.
The installed command is `oo`.
It does not need Bun, Node.js, or an npm download at runtime.
The build includes the upstream bundled skills and generates the Open Flow references before compilation.

The catalog supports `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`.
It exposes `packages.<system>.oo-cli` and `overlays.default`, which adds `pkgs.oo-cli`.
The overlay takes the Bun compiler from this catalog's locked nixpkgs input, not from the host package set.
Keep this input independent: older host versions of Bun cannot build the upstream ESM bytecode executable correctly.
The existing `pass-cli` package remains available through the same interfaces.

The personal macOS configuration uses the compiled package through its existing connection-settings wrapper.
The sandbox configuration installs the compiled package directly.
These changes take effect after the corresponding Home Manager or system configuration is rebuilt.
They do not activate a configuration automatically.

## Validate oo-cli

```bash
nix flake check ./nix/share/packages
vp run --filter @app/nix check
```

The package's install checks run with an isolated home directory and telemetry disabled.
They check the version, help output, bundled-skill metadata, and generated Open Flow reference.
The CLI checks use an empty `PATH` to detect an external runtime dependency.
`nix flake check` builds the package for the current system, not every supported system.

## Update oo-cli

1. Select an upstream release that satisfies the repository's release-age policy.
2. Update `version`, `rev`, the source hash, and `BUILD_TIMESTAMP` in `oo-cli.nix`.
   Use the source commit's Unix timestamp in milliseconds for `BUILD_TIMESTAMP`.
3. Set the dependency `outputHash` to `lib.fakeHash` and build the package.
   The expected hash-mismatch error reports the new dependency hash.
4. Replace `lib.fakeHash` with that hash, then run the validation commands above.
5. Update the release link in this document.

Dependencies come from the upstream `bun.lock` with lifecycle scripts disabled.
The dependency output includes optional packages for all operating systems and CPU architectures, so its hash is not selected per host.
Only the upstream Open Flow reference-generation script runs during compilation.
Use Nix to update the installed version rather than the CLI's self-update commands.

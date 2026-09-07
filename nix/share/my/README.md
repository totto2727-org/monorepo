# Personal application flakes

Use the common flake for cross-platform applications and opt into the macOS flake separately for GlossShift.
Both expose overlays and individually selectable packages, without installing every application automatically.
Archived application repositories are excluded from the catalog inputs, overlays, and packages.

## Usage

In a consumer under `nix/`, add the shared inputs and use their overlays to select applications for Home Manager:

```nix
{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    my = {
      url = "path:../share/my";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-macos = {
      url = "path:../share/my/macos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, my, my-macos, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ my.overlays.default my-macos.overlays.default ];
      };
    in
    {
      homeManagerModules.personal-apps = {
        home.packages = [ pkgs.wt pkgs.glossshift ];
      };
    };
}
```

Import `homeManagerModules.personal-apps` in a Home Manager configuration to install the selected tools, including both GlossShift binaries and `GlossShift.app`.
The repository's [personal macOS configuration](../../macos/flake.nix) applies both overlays and retains the GitHub-token wrapper around `wt`.
The work macOS configuration does not use these catalogs and retains its existing package selection and Mooncakes-based `wt` wrapper.
For Linux, omit the `my-macos` input and overlay.

### Updating applications

The upstream workflows publish pushes to `main` as FlakeHub `0.1` rolling releases.
The URL selects the latest published release in that series, not a literal Git branch URL, and `flake.lock` pins the resolved source until explicitly updated.
A failed or disabled upstream publication therefore does not advance the available release.
The common flake also pins a Mooncakes registry index because the published `wt` lock predates a required dependency version.
See the official [rolling release documentation](https://docs.determinate.systems/flakehub/concepts/semver/) and [publishing action](https://github.com/DeterminateSystems/flakehub-push#rolling-releases).

From the repository root, refresh the catalogs, then refresh the consuming configurations:

```bash
nix flake update --flake ./nix/share/my
nix flake update --flake ./nix/share/my/macos
nix flake update my my-macos --flake ./nix/macos
```

These commands update lock files only. They do not activate a system configuration.

## API

### `overlays.default`

`my.overlays.default` composes the upstream application overlays using the consumer's package set.
It exposes only applications whose upstream flake advertises the host system.
`my-macos.overlays.default` exposes `glossshift` and `gshift` only on `aarch64-darwin` and leaves other systems unchanged.
The common flake has no dependency on the macOS flake.

### `packages.<system>.<name>`

Select packages directly when an overlay is unnecessary, for example `my.packages.aarch64-darwin.wt` or `my-macos.packages.aarch64-darwin.glossshift`.
The catalog deliberately has no `default` package because it represents independent applications.

| Flake      | Systems                          | Packages                        |
| ---------- | -------------------------------- | ------------------------------- |
| `my`       | `aarch64-darwin`, `x86_64-linux` | `flowdeck`, `topcoat-cli`, `wt` |
| `my`       | `aarch64-linux`                  | `flowdeck`, `topcoat-cli`       |
| `my/macos` | `aarch64-darwin`                 | `glossshift`, `gshift`          |

`gshift` is the upstream variant with the CLI as its main program.
Both GlossShift variants contain the same application binaries, so install only one variant in a profile.
`c-plugin` is not yet available from FlakeHub. Publication and catalog registration are tracked in [c-plugin#21](https://github.com/totto2727-org/c-plugin/issues/21).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._

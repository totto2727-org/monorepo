# Nix maintenance

Before any Nix dependency update or system upgrade, read [the update inventory](share/packages/README.md).
Check every inventory entry, including packages that `nix flake update` cannot update.
Follow the package-specific update and validation steps before running a system rebuild.
Keep the inventory current when you add, remove, or change an independently pinned package under `nix/`.
Do not treat a successful flake lock update as proof that local package versions are current.

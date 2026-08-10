{ buildGoModule }:
buildGoModule {
  pname = "atlas-to-kysely";
  version = "0.0.0";

  src = ./.;
  vendorHash = "sha256-dv6WFifPKOLchnf/WheHv7nyZ3aS9BuiNVUp0N4oO3Q=";

  meta.mainProgram = "atlas-to-kysely";
}

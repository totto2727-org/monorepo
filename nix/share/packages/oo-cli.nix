{
  lib,
  bun2nix,
  fetchFromGitHub,
}:
let
  version = "1.9.8";
  rev = "17f5e45a500cca5f02f654c2ab018f5c0a81d33d";
in
bun2nix.mkDerivation {
  pname = "oo";
  inherit version;
  src = fetchFromGitHub {
    owner = "oomol-lab";
    repo = "oo-cli";
    inherit rev;
    hash = "sha256-rLwndZ4faA3F14BDIz7KkRVzFGCtJZLrrltzqbKWTJA=";
  };
  module = "index.ts";
  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./oo-cli-bun.nix;
  };
  extraBunBuildFlags = [
    "--format=esm"
    "--no-compile-autoload-dotenv"
    "--no-compile-autoload-bunfig"
    "--define"
    ''BUILD_VERSION="${version}"''
  ];
  meta = {
    description = "OOMOL CLI for hosted capabilities and connected accounts";
    homepage = "https://github.com/oomol-lab/oo-cli";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}

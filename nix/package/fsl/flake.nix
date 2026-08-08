{
  description = "FSL compiler package";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          version = "3.1.0";
          release =
            {
              aarch64-darwin = {
                asset = "fslc-macos-arm64";
                hash = "sha256-uRfqUavZ5q64pQhspn+n4EpzBvSdJs915LVbNUa6B7Y=";
              };
              x86_64-linux = {
                asset = "fslc-linux-x64";
                hash = "sha256-HnViKqifE5cJH5vbHwh+08tuikwywoSUpYHt7nrV+R4=";
              };
            }
            .${system};
        in
        {
          fslc = pkgs.stdenv.mkDerivation {
            pname = "fslc";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/ymm-oss/fsl/releases/download/v${version}/${release.asset}";
              hash = release.hash;
            };

            dontUnpack = true;

            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.autoPatchelfHook
            ];
            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.stdenv.cc.cc.lib
              pkgs.openssl
              pkgs.zlib
            ];

            installPhase = ''
              install -Dm755 "$src" "$out/bin/fslc"
            '';

            doInstallCheck = true;
            installCheckPhase = ''
              "$out/bin/fslc" --version | grep -Fx "fslc ${version}"
            '';

            meta = {
              description = "Formal Specification Language compiler";
              homepage = "https://github.com/ymm-oss/fsl";
              license = pkgs.lib.licenses.mit;
              mainProgram = "fslc";
              platforms = supportedSystems;
            };
          };
        }
      );

      overlays.default = _final: prev: {
        fslc = self.packages.${prev.stdenv.hostPlatform.system}.fslc;
      };
    };
}

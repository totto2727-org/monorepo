{
  description = "macOS-only personal applications published from main on FlakeHub";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    glossshift = {
      url = "https://flakehub.com/f/totto2727-org/glossshift/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      glossshift,
    }:
    {
      overlays.default =
        final: previous:
        nixpkgs.lib.optionalAttrs (builtins.hasAttr previous.stdenv.hostPlatform.system glossshift.packages) (
          glossshift.overlays.default final previous
        );

      packages = nixpkgs.lib.genAttrs [ "aarch64-darwin" ] (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs) glossshift gshift;
        }
      );
    };
}

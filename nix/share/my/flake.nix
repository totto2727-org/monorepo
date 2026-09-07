{
  description = "Shared personal applications published from main on FlakeHub";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    # Published application locks predate some of their Mooncakes dependencies.
    moon-registry = {
      url = "git+https://mooncakes.io/git/index";
      flake = false;
    };
    bw = {
      url = "https://flakehub.com/f/totto2727-org/bw/0.1";
      inputs.moon-registry.follows = "moon-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flowdeck = {
      url = "https://flakehub.com/f/totto2727-org/flowdeck/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mdt = {
      url = "https://flakehub.com/f/totto2727-org/mdt/0.1";
      inputs.moon-registry.follows = "moon-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wt = {
      url = "https://flakehub.com/f/totto2727-org/wt/0.1";
      inputs.moon-registry.follows = "moon-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      bw,
      flowdeck,
      mdt,
      wt,
      ...
    }:
    let
      applications = [
        bw
        flowdeck
        mdt
        wt
      ];
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      # Keep unsupported applications out of the host package set.
      overlays.default = nixpkgs.lib.composeManyExtensions (
        map (
          application: final: previous:
          nixpkgs.lib.optionalAttrs (builtins.hasAttr previous.stdenv.hostPlatform.system application.packages) (
            application.overlays.default final previous
          )
        ) applications
      );

      packages = nixpkgs.lib.genAttrs supportedSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          packageNames = nixpkgs.lib.concatMap (
            application:
            builtins.filter (name: name != "default") (
              builtins.attrNames (application.packages.${system} or { })
            )
          ) applications;
        in
        nixpkgs.lib.getAttrs packageNames pkgs
      );
    };
}

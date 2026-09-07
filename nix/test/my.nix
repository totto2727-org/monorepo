let
  my = builtins.getFlake (toString ../share/my);
  macos = builtins.getFlake (toString ../share/my/macos);
  inherit (my.inputs.nixpkgs) lib;
  commonPackages = [
    "flowdeck"
    "topcoat-cli"
    "wt"
  ];
  expectedPackages = {
    aarch64-darwin = commonPackages;
    aarch64-linux = [
      "flowdeck"
      "topcoat-cli"
    ];
    x86_64-linux = commonPackages;
  };
  overlayPackages =
    system:
    let
      pkgs = import my.inputs.nixpkgs { inherit system; };
    in
    builtins.attrNames (my.overlays.default pkgs pkgs);
  macosOverlayPackages =
    system:
    let
      pkgs = import macos.inputs.nixpkgs { inherit system; };
    in
    builtins.attrNames (macos.overlays.default pkgs pkgs);
  system = builtins.currentSystem;
  pkgs = import my.inputs.nixpkgs {
    inherit system;
    overlays = [ my.overlays.default ];
  };
  macosPkgs = import macos.inputs.nixpkgs {
    inherit system;
    overlays = [ macos.overlays.default ];
  };
  tests = {
    testCommonPackageMatrix = {
      expr = builtins.mapAttrs (_: builtins.attrNames) my.packages;
      expected = expectedPackages;
    };
    testCommonOverlayMatrix = {
      expr = lib.genAttrs (builtins.attrNames expectedPackages) overlayPackages;
      expected = expectedPackages;
    };
    testUnsupportedCommonOverlay = {
      expr = overlayPackages "riscv64-linux";
      expected = [ ];
    };
    testMacosPackageMatrix = {
      expr = builtins.mapAttrs (_: builtins.attrNames) macos.packages;
      expected = {
        aarch64-darwin = [
          "glossshift"
          "gshift"
        ];
      };
    };
    testMacosOverlayMatrix = {
      expr = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "riscv64-linux"
        "x86_64-linux"
      ] macosOverlayPackages;
      expected = {
        aarch64-darwin = [
          "glossshift"
          "gshift"
        ];
        aarch64-linux = [ ];
        riscv64-linux = [ ];
        x86_64-linux = [ ];
      };
    };
    # Compare actual derivations, not just attribute names, on the build host.
    testHostCommonOverlayDerivations = {
      expr = builtins.mapAttrs (name: _: pkgs.${name}.drvPath) (my.packages.${system} or { });
      expected = builtins.mapAttrs (_: package: package.drvPath) (my.packages.${system} or { });
    };
    testHostMacosOverlayDerivations = {
      expr = builtins.mapAttrs (name: _: macosPkgs.${name}.drvPath) (macos.packages.${system} or { });
      expected = builtins.mapAttrs (_: package: package.drvPath) (macos.packages.${system} or { });
    };
  };
  failures = lib.runTests tests;
in
if failures == [ ] then { passed = builtins.attrNames tests; } else throw (builtins.toJSON failures)

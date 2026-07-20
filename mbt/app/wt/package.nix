{
  lib,
  moonPlatform,
  moonRegistryIndex,
  runCommand,
}:
let
  packageSrc = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.unions [
      ./moon.mod
      ./src
    ];
  };
  moonWork = builtins.toFile "wt-moon.work" ''
    members = [
      "./app/wt",
    ]
  '';
  src = runCommand "wt-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
  moonModJson = builtins.toFile "wt-moon.mod.json" (
    builtins.toJSON {
      name = "totto2727/wt";
      version = "0.1.0";
      deps = {
        "mizchi/admiral" = "0.1.0";
        "moonbitlang/async" = "0.19.2";
      };
      description = "Native MoonBit Git worktree manager with PR awareness";
      license = "MIT";
      "preferred-target" = "native";
      repository = "https://github.com/totto2727-org/monorepo";
      source = "src";
      "supported-targets" = "native";
    }
  );
in
moonPlatform.buildMoonPackage {
  inherit src moonModJson moonRegistryIndex;
  moonFlags = [ "app/wt/src" ];
  doCheck = false;
  meta.mainProgram = "wt";
}

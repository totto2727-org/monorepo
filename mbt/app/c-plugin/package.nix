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
      ../../package/target-file-discovery/moon.mod
      ../../package/target-file-discovery/src
    ];
  };
  moonWork = builtins.toFile "c-plugin-moon.work" ''
    members = [
      "./app/c-plugin",
      "./package/target-file-discovery",
    ]
  '';
  src = runCommand "c-plugin-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
  moonModJson = builtins.toFile "c-plugin-moon.mod.json" (
    builtins.toJSON {
      name = "totto2727/c-plugin";
      version = "0.1.0";
      deps = {
        "mizchi/admiral" = "0.1.0";
        "moonbitlang/async" = "0.19.2";
        "moonbitlang/x" = "0.4.38";
      };
      description = "Native MoonBit Claude/Cursor/Codex plugin skill manager";
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
  moonFlags = [ "app/c-plugin/src" ];
  doCheck = false;
  meta.mainProgram = "c-plugin";
}

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
      ../../package/admiral/moon.mod
      ../../package/admiral/src
      ../../package/lens/moon.mod
      ../../package/lens/src
      ../../package/target-file-discovery/moon.mod
      ../../package/target-file-discovery/src
    ];
  };
  moonWork = builtins.toFile "c-plugin-moon.work" ''
    members = [
      "./app/c-plugin",
      "./package/admiral",
      "./package/lens",
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
      version = "0.2.0";
      deps = {
        "moonbitlang/async" = "0.20.1";
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

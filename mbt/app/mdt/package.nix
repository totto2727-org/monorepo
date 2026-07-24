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
      ../../package/opencode-sdk/moon.mod
      ../../package/opencode-sdk/src
    ];
  };
  moonWork = builtins.toFile "mdt-moon.work" ''
    members = [
      "./app/mdt",
      "./package/admiral",
      "./package/opencode-sdk",
    ]
  '';
  src = runCommand "mdt-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
  moonModJson = builtins.toFile "mdt-moon.mod.json" (
    builtins.toJSON {
      name = "totto2727/mdt";
      version = "0.1.2";
      deps = {
        "DC-Z-lab/moonllm" = "0.1.0";
        "moonbitlang/async" = "0.20.1";
        "moonbitlang/x" = "0.4.38";
      };
      description = "Native MoonBit CLI for translating Markdown with OpenCode";
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
  moonFlags = [ "app/mdt/src" ];
  doCheck = false;
  meta.mainProgram = "mdt";
}

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
  moonWork = builtins.toFile "bw-moon.work" ''
    members = [
      "./app/bw",
    ]
  '';
  src = runCommand "bw-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
  moonModJson = builtins.toFile "bw-moon.mod.json" (
    builtins.toJSON {
      name = "totto2727/bw";
      version = "0.1.7";
      deps = {
        "gmlewis/base64" = "0.16.10";
        "mizchi/admiral" = "0.1.0";
        "moonbitlang/async" = "0.19.2";
        "moonbitlang/x" = "0.4.38";
      };
      description = "Native MoonBit CLI for Cloudflare Browser Rendering API";
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
  moonFlags = [ "app/bw/src" ];
  doCheck = false;
  meta.mainProgram = "bw";
}

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
in
moonPlatform.buildMoonPackage {
  inherit src moonRegistryIndex;
  moonMod = ./moon.mod;
  moonFlags = [ "app/bw/src" ];
  doCheck = false;
  meta.mainProgram = "bw";
}

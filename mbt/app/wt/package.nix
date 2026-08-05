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
in
moonPlatform.buildMoonPackage {
  inherit src moonRegistryIndex;
  moonMod = ./moon.mod;
  moonFlags = [ "app/wt/src" ];
  doCheck = false;
  meta.mainProgram = "wt";
}

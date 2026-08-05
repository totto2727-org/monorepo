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
in
moonPlatform.buildMoonPackage {
  inherit src moonRegistryIndex;
  moonMod = ./moon.mod;
  moonFlags = [ "app/c-plugin/src" ];
  doCheck = false;
  meta.mainProgram = "c-plugin";
}

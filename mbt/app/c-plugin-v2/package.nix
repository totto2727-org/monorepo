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
  moonWork = builtins.toFile "c-plugin-v2-moon.work" ''
    members = [
      "./app/c-plugin-v2",
      "./package/admiral",
      "./package/lens",
      "./package/target-file-discovery",
    ]
  '';
  src = runCommand "c-plugin-v2-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
in
moonPlatform.buildMoonPackage {
  inherit src moonRegistryIndex;
  moonMod = ./moon.mod;
  moonFlags = [ "app/c-plugin-v2/src" ];
  doCheck = false;
  meta.mainProgram = "c-plugin-v2";
}

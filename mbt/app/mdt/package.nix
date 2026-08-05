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
      ../../package/opencode-sdk/moon.mod
      ../../package/opencode-sdk/src
    ];
  };
  moonWork = builtins.toFile "mdt-moon.work" ''
    members = [
      "./app/mdt",
      "./package/admiral",
      "./package/lens",
      "./package/opencode-sdk",
    ]
  '';
  src = runCommand "mdt-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
in
moonPlatform.buildMoonPackage {
  inherit src moonRegistryIndex;
  moonMod = ./moon.mod;
  moonFlags = [ "app/mdt/src" ];
  doCheck = false;
  meta.mainProgram = "mdt";
}

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
  registryExcludedManifestEntries = [
    ''source = "src"''
    ''"totto2727/admiral@0.6.1",''
    ''"totto2727/lens@0.4.0",''
    ''"totto2727/target-file-discovery@0.2.1",''
  ];
  moonMod = builtins.toFile "c-plugin-v2.moon.mod" (
    builtins.replaceStrings registryExcludedManifestEntries
      (lib.replicate (builtins.length registryExcludedManifestEntries) "")
      (builtins.readFile ./moon.mod)
  );
  src = runCommand "c-plugin-v2-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
in
moonPlatform.buildMoonPackage {
  inherit src moonMod moonRegistryIndex;
  moonFlags = [ "app/c-plugin-v2/src" ];
  doCheck = false;
  meta.mainProgram = "c-plugin-v2";
}

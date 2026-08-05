{
  lib,
  moonPlatform,
  moonRegistryIndex,
  runCommand,
  stdenv,
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
  cachedRegistry = moonPlatform.buildCachedRegistry {
    registryIndexSrc = moonRegistryIndex;
    moonModDepsSet = {
      "mizchi/bit_lib" = "0.45.6";
      "mizchi/bit_osfs" = "0.45.6";
      "mizchi/tui" = "0.10.0";
      "moonbitlang/async" = "0.20.1";
      "moonbitlang/x" = "0.4.45";
      "shu-kitamura/sha256" = "0.1.1";
    };
  };
  moonHome = moonPlatform.bundleWithRegistry { inherit cachedRegistry; };
in
stdenv.mkDerivation {
  pname = "c-plugin-v2";
  version = "0.1.0";
  inherit src;
  nativeBuildInputs = [ moonHome ];
  env.MOON_HOME = "${moonHome}";
  doCheck = false;
  buildPhase = ''
    runHook preBuild
    writable_moon_home="$TMPDIR/moon_home"
    cp -rL "$MOON_HOME" "$writable_moon_home"
    chmod -R u+w "$writable_moon_home"
    export MOON_HOME="$writable_moon_home"
    export HOME="$TMPDIR"
    moon build --target native --release app/c-plugin-v2/src
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    find _build/native/release/build -name 'c-plugin-v2.exe' -type f -perm -0111 -exec install -Dm755 '{}' "$out/bin/c-plugin-v2" \;
    runHook postInstall
  '';
  meta.mainProgram = "c-plugin-v2";
}

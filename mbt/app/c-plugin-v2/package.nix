{
  lib,
  moonPlatform,
  moonRegistryIndex,
  runCommand,
  stdenv,
}:
let
  dependencies = {
    "mizchi/bit_lib" = "0.45.6";
    "mizchi/bit_osfs" = "0.45.6";
    "mizchi/tui" = "0.10.0";
    "moonbitlang/async" = "0.20.3";
    "moonbitlang/x" = "0.4.50";
    "shu-kitamura/sha256" = "0.1.1";
    "totto2727/admiral" = "0.6.2";
    "totto2727/lens" = "0.4.0";
    "totto2727/target-file-discovery" = "0.2.1";
  };
  cachedRegistry = moonPlatform.buildCachedRegistry {
    moonModDepsSet = dependencies;
    registryIndexSrc = moonRegistryIndex;
  };
  moonHome = moonPlatform.bundleWithRegistry {
    inherit cachedRegistry;
  };
  packageSrc = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.unions [
      ./moon.mod
      ./src
    ];
  };
  moonWork = builtins.toFile "c-plugin-v2-moon.work" ''
    members = [
      "./app/c-plugin-v2",
    ]
  '';
  src = runCommand "c-plugin-v2-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
in
stdenv.mkDerivation {
  pname = "c-plugin-v2";
  version = "0.1.0";
  inherit src;
  nativeBuildInputs = [ moonHome ];
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild

    writable_home="$TMPDIR/moon_home"
    cp -rL ${moonHome} "$writable_home"
    chmod -R u+w "$writable_home"
    export MOON_HOME="$writable_home"
    export HOME="$TMPDIR"

    moon_bin="$MOON_HOME/bin/.moon-wrapped"
    "$moon_bin" build --target native --release --strip app/c-plugin-v2/src

    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -Dm755 _build/native/release/build/c-plugin-v2.exe "$out/bin/c-plugin-v2"

    runHook postInstall
  '';
  meta = {
    description = "Native MoonBit bootstrap for c-plugin v2";
    homepage = "https://github.com/totto2727-org/monorepo";
    license = lib.licenses.mit;
    mainProgram = "c-plugin-v2";
  };
}

{
  lib,
  moonPlatform,
  moonRegistryIndex,
  runCommand,
  stdenv,
}:
let
  dependencies = {
    "moonbitlang/async" = "0.20.3";
    "moonbitlang/x" = "0.4.50";
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
  moonWork = builtins.toFile "c-plugin-moon.work" ''
    members = [
      "./app/c-plugin",
    ]
  '';
  src = runCommand "c-plugin-moonbit-workspace-source" { } ''
    mkdir -p "$out"
    cp -R ${packageSrc}/. "$out/"
    cp ${moonWork} "$out/moon.work"
  '';
in
stdenv.mkDerivation {
  pname = "c-plugin";
  version = "0.2.1";
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
    "$moon_bin" build --target native --release --strip app/c-plugin/src

    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -Dm755 _build/native/release/build/c-plugin.exe "$out/bin/c-plugin"

    runHook postInstall
  '';
  meta = {
    description = "Native MoonBit Claude/Cursor/Codex plugin skill manager";
    homepage = "https://github.com/totto2727-org/monorepo";
    license = lib.licenses.mit;
    mainProgram = "c-plugin";
  };
}

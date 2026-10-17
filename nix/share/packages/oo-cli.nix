{
  lib,
  bun2nix,
  fetchFromGitHub,
  jq,
}:
let
  version = "1.9.8";
  rev = "17f5e45a500cca5f02f654c2ab018f5c0a81d33d";
in
bun2nix.mkDerivation {
  pname = "oo";
  inherit version;
  src = fetchFromGitHub {
    owner = "oomol-lab";
    repo = "oo-cli";
    inherit rev;
    hash = "sha256-rLwndZ4faA3F14BDIz7KkRVzFGCtJZLrrltzqbKWTJA=";
  };
  module = "index.ts";
  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./oo-cli-bun.nix;
  };
  bunInstallFlags = [
    "--frozen-lockfile"
    "--production"
    "--offline"
  ];
  dontRunLifecycleScripts = true;
  preBuild = ''
    # Generate only the upstream references embedded in the executable.
    bun run contrib/skills/sync-open-flow-docs.ts
  '';
  removeBunBuildFlags = [ "--sourcemap" ];
  extraBunBuildFlags = [
    "--format=esm"
    "--no-compile-autoload-dotenv"
    "--no-compile-autoload-bunfig"
    "--asset-naming=[name]-[hash].[ext]"
    "--define"
    ''BUILD_VERSION="${version}"''
    "--define"
    "BUILD_TIMESTAMP=1791882804000"
    "--define"
    ''GIT_COMMIT="${rev}"''
  ];
  doInstallCheck = true;
  nativeInstallCheckInputs = [ jq ];
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/check-home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export OO_TELEMETRY_DISABLED=1
    mkdir -p "$HOME/.claude"
    # An empty PATH proves that neither Bun nor Node is needed at runtime.
    PATH= "$out/bin/oo" --version > /dev/null
    PATH= "$out/bin/oo" version --json > version.json
    jq -e '.version == "${version}" and .commit == "${builtins.substring 0 8 rev}"
      and .buildTime == "2026-10-13T09:13:24.000Z"' version.json
    PATH= "$out/bin/oo" --help > /dev/null
    PATH= "$out/bin/oo" skills info --source bundled --json > skills.json
    jq -e '.summary.bundledSkills == 4 and all(.skills[];
      all(.hosts[]; .version == "${version}" and .controlState == "controlled"))' skills.json
    test -s "$HOME/.claude/skills/oo/SKILL.md"
    grep -F 'oo flow' "$HOME/.agents/skills/oo/references/flow-authoring.md" > /dev/null
    runHook postInstallCheck
  '';
  meta = {
    description = "OOMOL CLI for hosted capabilities and connected accounts";
    homepage = "https://github.com/oomol-lab/oo-cli";
    license = lib.licenses.mit;
    mainProgram = "oo";
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}

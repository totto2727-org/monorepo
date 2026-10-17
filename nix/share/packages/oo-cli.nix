{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  cacert,
  jq,
}:
let
  version = "1.9.8";
  rev = "17f5e45a500cca5f02f654c2ab018f5c0a81d33d";
  src = fetchFromGitHub {
    owner = "oomol-lab";
    repo = "oo-cli";
    inherit rev;
    hash = "sha256-rLwndZ4faA3F14BDIz7KkRVzFGCtJZLrrltzqbKWTJA=";
  };
  nodeModules = stdenvNoCC.mkDerivation {
    pname = "oo-cli-node-modules";
    inherit version src;
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    dontFixup = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
      export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
      # Fetch all optional platforms so this fixed output is shared across hosts.
      bun install --frozen-lockfile --production --ignore-scripts --linker hoisted --os '*' --cpu '*'
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      cp -R node_modules "$out"
      runHook postInstall
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-HA3yLFHOuD/d40ljqXFrMgsdTRnDuE0YxxHZlhUvk8s=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "oo-cli";
  inherit version src;
  nativeBuildInputs = [ bun ];
  dontConfigure = true;
  # Stripping a Bun executable can remove its embedded application and assets.
  dontStrip = true;
  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR"
    cp -R ${nodeModules} node_modules
    chmod -R u+w node_modules
    # Run only the upstream asset-generation step, without installation scripts.
    bun run contrib/skills/sync-open-flow-docs.ts
    # Use the host Bun executable, avoiding target-runtime downloads in the sandbox.
    bun build --compile --bytecode --format esm --minify \
      --no-compile-autoload-dotenv --no-compile-autoload-bunfig \
      --asset-naming='[name]-[hash].[ext]' \
      --define 'BUILD_VERSION="${version}"' \
      --define 'BUILD_TIMESTAMP=1791882804000' \
      --define 'GIT_COMMIT="${rev}"' \
      ./index.ts --outfile oo
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 oo "$out/bin/oo"
    runHook postInstall
  '';
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

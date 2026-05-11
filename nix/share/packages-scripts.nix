{ pkgs }:

let
  inherit (pkgs) writeShellScriptBin;

  # --- shared wrappers (no secrets) ---

  exocortex-mcp = writeShellScriptBin "exocortex-mcp" ''
    exec ${pkgs.uv}/bin/uvx \
      --from "git+https://github.com/fuwasegu/exocortex" \
      exocortex --mode proxy --ensure-server "$@"
  '';

  docker-credential-gh = writeShellScriptBin "docker-credential-gh" ''
    set -e

    cmd="$1"
    if [ "erase" = "$cmd" ]; then
      cat - >/dev/null
      exit 0
    fi
    if [ "store" = "$cmd" ]; then
      cat - >/dev/null
      exit 0
    fi
    if [ "get" != "$cmd" ]; then
      exit 1
    fi

    host="$(cat -)"
    host="''${host#https://}"
    host="''${host%/}"
    if [ "$host" != "ghcr.io" ] && [ "$host" != "docker.pkg.github.com" ]; then
      exit 1
    fi

    token="$(gh config get -h github.com oauth_token)"
    if [ -z "$token" ]; then
      exit 1
    fi

    printf '{"Username":"%s", "Secret":"%s"}\n' "$(gh config get -h github.com user)" "$token"
  '';

  # --- wrappers with pass-cli (macos) ---

  macos-bsx = writeShellScriptBin "bsx" ''
    export BRAVE_SEARCH_API_KEY="$(pass-cli get brave-search/api-key --quiet -f password)"
    exec bx "$@"
  '';

  macos-bwx = writeShellScriptBin "bwx" ''
    export CLOUDFLARE_API_TOKEN="$(pass-cli get cloudflare/browser-rendering-api-key --quiet -f password)"
    export CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet -f password)"
    exec bw "$@"
  '';

  macos-o = writeShellScriptBin "o" ''
    export ANTHROPIC_API_KEY="x"
    export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
    exec opencode "$@"
  '';

  macos-work-c = writeShellScriptBin "c" ''
    export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
    exec claude "$@"
  '';

  # --- wrappers without pass-cli (sandbox, OpenShell injects env vars) ---

  sandbox-bsx = writeShellScriptBin "bsx" ''
    exec bx "$@"
  '';

  sandbox-bwx = writeShellScriptBin "bwx" ''
    exec bw "$@"
  '';

  sandbox-o = writeShellScriptBin "o" ''
    export ANTHROPIC_API_KEY="x"
    export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
    exec opencode "$@"
  '';


in
{
  macos = [
    exocortex-mcp
    docker-credential-gh
    macos-bsx
    macos-bwx
    macos-o
  ];

  macos-work = [
    docker-credential-gh
    macos-work-c
  ];

  sandbox = [
    exocortex-mcp
    docker-credential-gh
    sandbox-bsx
    sandbox-bwx
    sandbox-o
  ];
}

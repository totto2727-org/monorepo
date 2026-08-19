{ pkgs, npm }:

let
  inherit (pkgs) lib writeShellScriptBin;

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

  macos-bx = writeShellScriptBin "bx" ''
    export BRAVE_SEARCH_API_KEY="$(pass-cli get brave-search/api-key --quiet -f password)"
    exec $HOME/.local/bin/bx "$@"
  '';

  macos-cf = writeShellScriptBin "cf" ''
    set -e

    CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet -f password)"
    CLOUDFLARE_API_TOKEN="$(pass-cli get cloudflare/browser-rendering-api-key --quiet -f password)"
    export CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_TOKEN
    exec ${
      npm {
        binName = "cf";
        packageName = "cf";
        runtime = "node";
      }
    }/bin/cf "$@"
  '';

  macos-o = writeShellScriptBin "o" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec opencode "$@"
  '';

  macos-c = writeShellScriptBin "c" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec codex "$@"
  '';

  macos-work-c = writeShellScriptBin "c" ''
    export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
    exec claude "$@"
  '';

  macos-linear-mcp = writeShellScriptBin "linear-mcp" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec bunx mcp-remote \
      https://mcp.linear.app/mcp \
      --transport http-only \
      --header "Authorization:Bearer ''${LINEAR_API_KEY}" \
      "$@"
  '';

  # --- wrappers without pass-cli (sandbox, OpenShell injects env vars) ---

  sandbox-bx = writeShellScriptBin "bx" ''
    exec $HOME/.local/bin/bx "$@"
  '';

  sandbox-o = writeShellScriptBin "o" ''
    exec opencode "$@"
  '';

  sandbox-c = writeShellScriptBin "c" ''
    exec codex "$@"
  '';

  sandbox-linear-mcp = writeShellScriptBin "linear-mcp" ''
    exec bunx mcp-remote \
      https://mcp.linear.app/mcp \
      --transport http-only \
      --header "Authorization:Bearer ''${LINEAR_API_KEY}" \
      "$@"
  '';

in
{
  macos = [
    exocortex-mcp
    docker-credential-gh
    macos-bx
    (lib.hiPrio macos-cf)
    macos-o
    macos-c
    macos-linear-mcp
  ];

  macos-work = [
    docker-credential-gh
    macos-work-c
  ];

  sandbox = [
    exocortex-mcp
    docker-credential-gh
    sandbox-bx
    sandbox-o
    sandbox-c
    sandbox-linear-mcp
  ];
}

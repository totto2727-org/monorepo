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

  macos-zai-mcp-server = writeShellScriptBin "zai-mcp-server" ''
    export Z_AI_API_KEY="$(pass-cli get z-ai/api-key --quiet -f password)"
    export Z_AI_MODE="ZAI"
    exec ${pkgs.bun}/bin/bunx -y @z_ai/mcp-server "$@"
  '';

  macos-zread-mcp = writeShellScriptBin "zread-mcp" ''
    export Z_AI_API_KEY="$(pass-cli get z-ai/api-key --quiet -f password)"
    exec ${pkgs.uv}/bin/uvx mcp-proxy --transport streamablehttp \
      --headers Authorization "Bearer $Z_AI_API_KEY" \
      https://api.z.ai/api/mcp/zread/mcp "$@"
  '';

  macos-brave-search-mcp = writeShellScriptBin "brave-search-mcp" ''
    export BRAVE_API_KEY="$(pass-cli get brave-search/api-key --quiet -f password)"
    exec ${pkgs.bun}/bin/bunx -y @brave/brave-search-mcp-server "$@"
  '';

  macos-web-reader-mcp = writeShellScriptBin "web-reader-mcp" ''
    export Z_AI_API_KEY="$(pass-cli get z-ai/api-key --quiet -f password)"
    exec ${pkgs.uv}/bin/uvx mcp-proxy --transport streamablehttp \
      --headers Authorization "Bearer $Z_AI_API_KEY" \
      https://api.z.ai/api/mcp/web_reader/mcp "$@"
  '';

  macos-d = writeShellScriptBin "d" ''
    export Z_AI_API_KEY="$(pass-cli get z-ai/api-key --quiet -f password)"
    export OPENCODE_ZEN_API_KEY="$(pass-cli get opencode-zen/api-key --quiet -f password)"
    export CLOUDFLARE_API_TOKEN="$(pass-cli get cloudflare/browser-rendering-api-key --quiet -f password)"
    export CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet -f password)"
    exec droid "$@"
  '';

  macos-c = writeShellScriptBin "c" ''
    export CLOUDFLARE_API_TOKEN="$(pass-cli get cloudflare/browser-rendering-api-key --quiet -f password)"
    export CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet -f password)"
    exec claude "$@"
  '';

  macos-o = writeShellScriptBin "o" ''
    export ANTHROPIC_API_KEY="x"
    export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
    export CLOUDFLARE_API_TOKEN="$(pass-cli get cloudflare/browser-rendering-api-key --quiet -f password)"
    export CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet -f password)"
    exec opencode "$@"
  '';

  macos-work-c = writeShellScriptBin "c" ''
    export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
    exec claude "$@"
  '';

  # --- wrappers without pass-cli (sandbox, OpenShell injects env vars) ---

  sandbox-c = writeShellScriptBin "c" ''
    exec claude "$@"
  '';

  sandbox-o = writeShellScriptBin "o" ''
    export ANTHROPIC_API_KEY="x"
    export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
    exec opencode "$@"
  '';

  sandbox-zai-mcp-server = writeShellScriptBin "zai-mcp-server" ''
    export Z_AI_MODE="ZAI"
    exec ${pkgs.bun}/bin/bunx -y @z_ai/mcp-server "$@"
  '';

  sandbox-zread-mcp = writeShellScriptBin "zread-mcp" ''
    exec ${pkgs.uv}/bin/uvx mcp-proxy --transport streamablehttp \
      --headers Authorization "Bearer $Z_AI_API_KEY" \
      https://api.z.ai/api/mcp/zread/mcp "$@"
  '';

  sandbox-brave-search-mcp = writeShellScriptBin "brave-search-mcp" ''
    exec ${pkgs.bun}/bin/bunx -y @brave/brave-search-mcp-server "$@"
  '';

  sandbox-web-reader-mcp = writeShellScriptBin "web-reader-mcp" ''
    exec ${pkgs.uv}/bin/uvx mcp-proxy --transport streamablehttp \
      --headers Authorization "Bearer $Z_AI_API_KEY" \
      https://api.z.ai/api/mcp/web_reader/mcp "$@"
  '';

in
{
  macos = [
    exocortex-mcp
    docker-credential-gh
    macos-zai-mcp-server
    macos-zread-mcp
    macos-brave-search-mcp
    macos-web-reader-mcp
    macos-d
    macos-c
    macos-o
  ];

  macos-work = [
    docker-credential-gh
    macos-work-c
  ];

  sandbox = [
    exocortex-mcp
    sandbox-zai-mcp-server
    sandbox-zread-mcp
    sandbox-brave-search-mcp
    sandbox-web-reader-mcp
    docker-credential-gh
    sandbox-c
    sandbox-o
  ];
}

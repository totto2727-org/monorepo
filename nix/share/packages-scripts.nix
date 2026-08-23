{ pkgs, npm }:

let
  inherit (pkgs) lib writeShellScriptBin;

  # --- shared wrappers (no secrets) ---

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
      }
    }/bin/cf "$@"
  '';

  macos-wt = writeShellScriptBin "wt" ''
    set -e

    export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
    exec ${
      (npm {
        binName = "wt";
        runtime = "moon";
        packageName = "totto2727/wt";
      })
    }/bin/wt "$@"
  '';

  macos-ctx7 = writeShellScriptBin "ctx7" ''
    set -e

    export CONTEXT7_API_KEY="$(pass-cli get context7/api-key --quiet -f password)"
    exec ${
      npm {
        binName = "ctx7";
        packageName = "ctx7";
      }
    }/bin/ctx7 "$@"
  '';

  macos-linear-mcp = writeShellScriptBin "linear-mcp" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec bunx mcp-remote \
      https://mcp.linear.app/mcp \
      --transport http-only \
      --header "Authorization:Bearer ''${LINEAR_API_KEY}" \
      "$@"
  '';

  macos-c = writeShellScriptBin "c" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec ${pkgs.codex}/bin/codex "$@"
  '';

  macos-j = writeShellScriptBin "j" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec jcode "$@"
  '';

  # --- wrappers for macos-work
  macos-work-c = writeShellScriptBin "c" ''
    export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
    exec claude "$@"
  '';

  # --- wrappers for sandbox

  sandbox-bx = writeShellScriptBin "bx" ''
    exec $HOME/.local/bin/bx "$@"
  '';

  sandbox-cf = npm {
    binName = "cf";
    packageName = "cf";
  };

  sandbox-wt = npm {
    binName = "wt";
    runtime = "moon";
    packageName = "totto2727/wt";
  };

  sandbox-ctx7 = npm {
    binName = "ctx7";
    packageName = "ctx7";
  };

  sandbox-linear-mcp = writeShellScriptBin "linear-mcp" ''
    exec bunx mcp-remote \
      https://mcp.linear.app/mcp \
      --transport http-only \
      --header "Authorization:Bearer ''${LINEAR_API_KEY}" \
      "$@"
  '';

  sandbox-c = writeShellScriptBin "c" ''
    exec ${pkgs.codex}/bin/codex "$@"
  '';

  sandbox-j = writeShellScriptBin "c" ''
    exec jcode "$@"
  '';
in
{
  macos = [
    docker-credential-gh
    macos-bx
    macos-cf
    macos-wt
    macos-ctx7
    macos-linear-mcp
    macos-c
    macos-j
  ];

  macos-work = [
    docker-credential-gh
    macos-wt
    macos-work-c
  ];

  sandbox = [
    docker-credential-gh
    sandbox-bx
    sandbox-cf
    sandbox-wt
    sandbox-ctx7
    sandbox-linear-mcp
    sandbox-c
    sandbox-j
  ];
}

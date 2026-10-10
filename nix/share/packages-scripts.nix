{ pkgs, npm }:

let
  inherit (pkgs) lib writeShellScriptBin;

  # --- shared wrappers (no secrets) ---

  monid = npm {
    binName = "monid";
    packageName = "@monid-ai/cli";
  };

  oo = npm {
    binName = "oo";
    packageName = "@oomol-lab/oo-cli";
  };

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

  openConnectorEnv = ''
    export OPENCONNECTOR_BASE_URL="$(${pkgs.pass-cli}/bin/pass-cli get open-connector/url --quiet --no-clipboard -f password)"
    export OPENCONNECTOR_TOKEN="$(${pkgs.pass-cli}/bin/pass-cli get open-connector/api-key --quiet --no-clipboard -f password)"
  '';

  macos-monid = writeShellScriptBin "monid" ''
    ${openConnectorEnv}
    umask 077

    # Use a per-invocation gateway profile without changing saved Monid keys.
    config_root="$(${pkgs.coreutils}/bin/mktemp -d "''${TMPDIR:-/tmp}/monid-gateway.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -rf -- "$config_root"' EXIT
    export XDG_CONFIG_HOME="$config_root"
    ${pkgs.coreutils}/bin/mkdir -p "$XDG_CONFIG_HOME/monid"
    ${pkgs.jq}/bin/jq -n '{active_key: "gateway", last_update_check: (now | todate)}' > "$XDG_CONFIG_HOME/monid/config.yaml"
    ${pkgs.jq}/bin/jq -n '{keys: {gateway: {key: env.OPENCONNECTOR_TOKEN, prefix: "gateway", added_at: (now | todate)}}}' > "$XDG_CONFIG_HOME/monid/credentials.yaml"
    export MONID_API_BASE_URL="''${OPENCONNECTOR_BASE_URL%/}/v1/passthrough/monid"

    ${monid}/bin/monid "$@"
  '';

  macos-oo = writeShellScriptBin "oo" ''
    ${openConnectorEnv}
    export OO_CONNECTOR_URL="$OPENCONNECTOR_BASE_URL"
    export OO_CONNECTOR_TOKEN="$OPENCONNECTOR_TOKEN"
    exec ${oo}/bin/oo "$@"
  '';

  macos-wt = writeShellScriptBin "wt" ''
    set -e

    export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
    exec ${pkgs.wt}/bin/wt "$@"
  '';

  macos-c = writeShellScriptBin "c" ''
    exec ${pkgs.codex}/bin/codex "$@"
  '';

  macos-j = writeShellScriptBin "j" ''
    set -e

    OPENCONNECTOR_BASE_URL="$(pass-cli get open-connector/url --quiet --no-clipboard -f password)"
    OPENCONNECTOR_TOKEN="$(pass-cli get open-connector/api-key --quiet --no-clipboard -f password)"
    export OPENCONNECTOR_BASE_URL OPENCONNECTOR_TOKEN

    CLOUDFLARE_ACCOUNT_ID="$(pass-cli get cloudflare/account-id --quiet --no-clipboard -f password)"
    CLOUDFLARE_AI_GATEWAY_ID="$(pass-cli get cloudflare/ai-gateway-id --quiet --no-clipboard -f password)"
    CLOUDFLARE_AI_GATEWAY_API_KEY="$(pass-cli get cloudflare/ai-gateway-api-key --quiet --no-clipboard -f password)"
    export CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_AI_GATEWAY_ID CLOUDFLARE_AI_GATEWAY_API_KEY
    exec jcode "$@"
  '';

  # --- wrappers for macos-work
  macos-work-c = writeShellScriptBin "c" ''
    exec claude "$@"
  '';

  # --- wrappers for sandbox

  sandbox-wt = npm {
    binName = "wt";
    runtime = "moon";
    packageName = "totto2727/wt";
  };

  sandbox-j = writeShellScriptBin "c" ''
    exec jcode "$@"
  '';
in
{
  sandbox = [
    monid
    oo
    docker-credential-gh
    sandbox-wt
    sandbox-j
  ];

  macos = [
    macos-monid
    macos-oo
    docker-credential-gh
    macos-wt
    macos-c
    macos-j
  ];

  macos-work = [
    docker-credential-gh
    macos-wt
    macos-work-c
  ];
}

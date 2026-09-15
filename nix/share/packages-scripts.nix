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

  macos-wt = writeShellScriptBin "wt" ''
    set -e

    export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
    exec ${pkgs.wt}/bin/wt "$@"
  '';

  macos-c = writeShellScriptBin "c" ''
    export LINEAR_API_KEY="$(pass-cli get linear/api-key --quiet -f password)"
    exec ${pkgs.codex}/bin/codex "$@"
  '';

  macos-j = writeShellScriptBin "j" ''
    set -e

    OPENCONNECTOR_BASE_URL="$(pass-cli get open-connector/url --quiet --no-clipboard -f password)"
    OPENCONNECTOR_TOKEN="$(pass-cli get open-connector/api-key --quiet --no-clipboard -f password)"
    if [ -z "$OPENCONNECTOR_BASE_URL" ] || [ -z "$OPENCONNECTOR_TOKEN" ]; then
      printf '%s\n' 'OpenConnector URL and token must not be empty.' >&2
      exit 1
    fi
    case "$OPENCONNECTOR_BASE_URL" in
      https://*) ;;
      *://*)
        printf '%s\n' 'OpenConnector requires an HTTPS origin.' >&2
        exit 1
        ;;
      *) OPENCONNECTOR_BASE_URL="https://$OPENCONNECTOR_BASE_URL" ;;
    esac
    OPENCONNECTOR_BASE_URL="''${OPENCONNECTOR_BASE_URL%/}"
    if ! [[ "$OPENCONNECTOR_BASE_URL" =~ ^https://[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]+)?$ ]]; then
      printf '%s\n' 'OpenConnector requires a hostname-based HTTPS origin without credentials or a path.' >&2
      exit 1
    fi
    export OPENCONNECTOR_BASE_URL OPENCONNECTOR_TOKEN
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
    docker-credential-gh
    sandbox-wt
    sandbox-j
  ];

  macos = [
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

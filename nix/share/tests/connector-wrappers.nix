let
  lock = builtins.fromJSON (builtins.readFile ../../macos/flake.lock);
  pkgs = import (builtins.fetchTree lock.nodes.nixpkgs.locked).outPath {
    system = builtins.currentSystem;
  };
  fakePass = pkgs.writeShellScriptBin "pass-cli" ''
    if [ "''${FAIL_PASS:-}" = 1 ]; then exit 42; fi
    case "$2" in
      open-connector/url) printf 'https://gateway.example/\n' ;;
      open-connector/api-key) printf 'fixture-token\n' ;;
      *) exit 43 ;;
    esac
  '';
  fakeNpm =
    { binName, ... }:
    pkgs.writeShellScriptBin binName ''
      set -e
      test "$OPENCONNECTOR_BASE_URL" = "$EXPECTED_URL"
      test "$OPENCONNECTOR_TOKEN" = "$EXPECTED_TOKEN"
      test "$#" -eq 2
      test "$1" = 'argument with spaces'
      test "$2" = '--json'
      ${
        if binName == "monid" then
          ''
            test "$MONID_API_BASE_URL" = "''${EXPECTED_URL%/}/v1/passthrough/monid"
            ${pkgs.jq}/bin/jq -e '.active_key == "gateway"' "$XDG_CONFIG_HOME/monid/config.yaml" >/dev/null
            ${pkgs.jq}/bin/jq -e '.keys.gateway.key == env.EXPECTED_TOKEN' "$XDG_CONFIG_HOME/monid/credentials.yaml" >/dev/null
            test "$(${pkgs.coreutils}/bin/stat -c %a "$XDG_CONFIG_HOME/monid/credentials.yaml")" = 600
            printf '%s' "$XDG_CONFIG_HOME" > "$PROFILE_CAPTURE"
          ''
        else
          ''
            test "$OO_CONNECTOR_URL" = "$EXPECTED_URL"
            test "$OO_CONNECTOR_TOKEN" = "$EXPECTED_TOKEN"
          ''
      }
      exit "''${CLI_EXIT:-0}"
    '';
  scripts = import ../packages-scripts.nix {
    pkgs = pkgs // {
      pass-cli = fakePass;
    };
    npm = fakeNpm;
  };
  monid = builtins.elemAt scripts.macos 0;
  oo = builtins.elemAt scripts.macos 1;
in
pkgs.runCommand "connector-wrapper-regression" { } ''
  export EXPECTED_URL=https://gateway.example/ EXPECTED_TOKEN=fixture-token PROFILE_CAPTURE="$PWD/profile"
  export XDG_CONFIG_HOME="$PWD/existing"
  mkdir -p "$XDG_CONFIG_HOME/monid"
  printf 'saved-profile' > "$XDG_CONFIG_HOME/monid/config.yaml"
  for cli in ${monid}/bin/monid ${oo}/bin/oo; do
    "$cli" 'argument with spaces' --json
    if FAIL_PASS=1 "$cli" 'argument with spaces' --json; then exit 1; else test "$?" = 42; fi
    export OPENCONNECTOR_BASE_URL=https://override.example OPENCONNECTOR_TOKEN=override-token
    EXPECTED_URL="$OPENCONNECTOR_BASE_URL" EXPECTED_TOKEN="$OPENCONNECTOR_TOKEN" FAIL_PASS=1 "$cli" 'argument with spaces' --json
    if OPENCONNECTOR_BASE_URL=http://insecure.example "$cli" 'argument with spaces' --json; then exit 1; fi
    unset OPENCONNECTOR_BASE_URL OPENCONNECTOR_TOKEN
    OPENCONNECTOR_BASE_URL=https://override.example EXPECTED_URL=https://override.example "$cli" 'argument with spaces' --json
    if CLI_EXIT=17 "$cli" 'argument with spaces' --json; then exit 1; else test "$?" = 17; fi
  done
  test ! -e "$(cat "$PROFILE_CAPTURE")"
  test "$(cat "$XDG_CONFIG_HOME/monid/config.yaml")" = saved-profile
  touch "$out"
''

# Meridian home-manager wrapper for darwin.
#
# The upstream module only emits a `systemd.user.services.meridian` unit, which
# is a no-op on darwin home-manager because `systemd.user.enable` defaults to
# `pkgs.stdenv.isLinux`. This wrapper imports the upstream module (so
# `services.meridian` options and `home.packages` are wired up) and mirrors the
# unit as a `launchd.agents.meridian` agent, deriving env vars from
# `config.services.meridian.settings.*` so it stays in sync with the option
# schema.
#
# Upstream module (env construction reproduced here verbatim):
# https://github.com/rynfar/meridian/blob/0a7ec3a3668042b817e0af2904f41c2e5a55fbef/nix/hm-module.nix
{ meridian }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.meridian;
  s = cfg.settings;

  # Workaround for the meridian 1.42.1 (rev 0a7ec3a) build under bun2nix's
  # hoisted linker: `bun build --splitting` emits a shared chunk
  # (tokenRefresh-*.js) with two `export {}` blocks that share identifiers,
  # which Node.js rejects with "SyntaxError: Duplicate export of
  # 'stopBackgroundRefresh'". The npm-published bundle does not hit this path
  # because `npm install` produces a different node_modules layout. Drop
  # `--splitting` from package.json's build script so bun emits one
  # self-contained file per entry instead of generating shared chunks.
  #
  # If upstream removes `--splitting` from scripts.build this sed becomes a
  # no-op (intentional). Source:
  # https://github.com/rynfar/meridian/blob/0a7ec3a3668042b817e0af2904f41c2e5a55fbef/package.json
  patchedMeridian = (meridian.packages.${pkgs.system}.meridian).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i 's/ --splitting//g' package.json
    '';
  });
in
{
  imports = [ meridian.homeManagerModules.default ];

  config = lib.mkMerge [
    {
      services.meridian.package = lib.mkDefault patchedMeridian;
    }

    (lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      xdg.configFile."opencode/plugins/meridian.ts".source =
        "${cfg.package}/lib/meridian/plugin/meridian.ts";

      launchd.agents.meridian = {
        enable = true;
        config = {
          ProgramArguments = [ "${cfg.package}/bin/meridian" ];
          RunAtLoad = true;
          KeepAlive = true;
          EnvironmentVariables = {
            MERIDIAN_PORT = toString s.port;
            MERIDIAN_HOST = s.host;
            MERIDIAN_IDLE_TIMEOUT_SECONDS = toString s.idleTimeoutSeconds;
          }
          // lib.optionalAttrs (s.passthrough != null) {
            MERIDIAN_PASSTHROUGH = if s.passthrough then "1" else "0";
          }
          // lib.optionalAttrs (s.defaultAgent != null) {
            MERIDIAN_DEFAULT_AGENT = s.defaultAgent;
          }
          // lib.optionalAttrs (s.sonnetModel != null) {
            MERIDIAN_SONNET_MODEL = s.sonnetModel;
          }
          // lib.optionalAttrs s.telemetry.persist {
            MERIDIAN_TELEMETRY_PERSIST = "1";
          }
          // lib.optionalAttrs (s.telemetry.retentionDays != null) {
            MERIDIAN_TELEMETRY_RETENTION_DAYS = toString s.telemetry.retentionDays;
          }
          // cfg.environment;
        };
      };
    })
  ];
}

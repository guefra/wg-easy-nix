{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.wg-easy;

  pkg = self.packages.${pkgs.system}.wg-easy;
in {
  options.services.wg-easy = {
    enable = mkEnableOption "wg-easy WireGuard + Web UI";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "wg-easy package to use for the systemd service.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Host address for wg-easy to bind to.";
    };

    port = mkOption {
      type = types.port;
      default = 51821;
      description = "Port for the wg-easy web UI.";
    };

    insecure = mkOption {
      type = types.bool;
      default = false;
      description = "Allow HTTP without TLS (only safe behind a reverse proxy).";
    };

    disableIPv6 = mkOption {
      type = types.bool;
      default = false;
      description = "Disable IPv6 support in generated configs.";
    };

    experimentalAwg = mkOption {
      type = types.bool;
      default = false;
      description = "Enable experimental AmneziaWG support. Requires AmneziaWG kernel module.";
    };

    overrideAutoAwg = mkOption {
      type = types.nullOr (types.enum ["awg" "wg"]);
      default = null;
      description = "Override automatic AmneziaWG detection. 'awg' forces AmneziaWG, 'wg' forces standard WireGuard, null uses auto-detection.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for the wg-easy service.";
    };

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User under which the wg-easy service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "root";
      description = "Group under which the wg-easy service runs.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /etc/wireguard 0700 root root -"
    ];

    systemd.services.wg-easy = {
      description = "wg-easy WireGuard + Web UI";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      path = [pkgs.bash];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        ExecStart = "${cfg.package}/bin/wg-easy-server";

        ReadWritePaths = ["/etc/wireguard"];

        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_RAW"
        ];
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_RAW"
        ];

        Restart = "on-failure";
        RestartSec = 5;
      };

      environment =
        {
          PORT = toString cfg.port;
          HOST = cfg.host;
          INSECURE =
            if cfg.insecure
            then "true"
            else "false";
          DISABLE_IPV6 =
            if cfg.disableIPv6
            then "true"
            else "false";
          EXPERIMENTAL_AWG =
            if cfg.experimentalAwg
            then "true"
            else "false";
        }
        // (
          if cfg.overrideAutoAwg != null
          then {OVERRIDE_AUTO_AWG = cfg.overrideAutoAwg;}
          else {}
        )
        // cfg.environment;
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sharry;
  user =
    if cfg.user == null
    then "sharry"
    else cfg.user;
  settingsFormat = pkgs.formats.json {};
  settingsConf = settingsFormat.generate "settings.conf" cfg.settings;
  sharryConf = pkgs.writeText "sharry.conf" ''
     sharry.restserver = {
       include "${settingsConf}"
       ${(optionalString (cfg.configOverridesFile != null) "include \"${cfg.configOverridesFile}\"")}
    }'';
in {
  ## interface
  options = {
    services.sharry = {
      enable = mkOption {
        default = false;
        description = "Whether to enable sharry.";
      };
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specify a user for running the application. If null, a new
          user is created.
        '';
      };
      configOverridesFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to a HOCON/JSON file containing configuration overrides to be
          merged at runtime. Useful for loading secrets.
        '';
      };
      package = mkOption {
        type = types.package;
        default = pkgs.sharry;
        description = ''
          The package providing the sharry binary.
        '';
      };
      settings = mkOption {
        type = settingsFormat.type;
        default = {};
        example = {
        };
        description = ''
          Configuration for sharry without the leading sharry.restserver.
          See https://eikek.github.io/sharry/doc/configure for available options
        '';
      };
    };
  };

  ## implementation
  config = mkIf config.services.sharry.enable {
    users.users."${user}" = mkIf (cfg.user == null) {
      name = user;
      isSystemUser = true;
      description = "Sharry user";
      group = "sharry";
    };
    users.groups = mkIf (cfg.user == null) {
      sharry = {};
    };

    systemd.services.sharry = {
      description = "Sharry Rest Server";
      after = ["networking.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.gawk];

      serviceConfig = {
        User = user;
        Group = mkIf (cfg.user == null) "sharry";
        ExecStart = "${cfg.package}/bin/sharry ${sharryConf}";
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
#
# The roundcube module in nix is designed for real-life
# applications. It requires a postgres server and only works over
# https.
#
# In contrast, this works with sqlite database and http.
#
with lib; let
  cfg = config.services.roundcubedev;
  fpm = config.services.phpfpm.pools.roundcubedev;

  # patch roundcube to disable mail address checks, otherwise we
  # cannot send to local domains :/
  myroundcube = pkgs.roundcube.overrideAttrs (finalAttrs: previousAttrs: {
    patchPhase = ''
      cd program/js
      rm common.min.js
      sed -i 's/return rx.test(input);/return true;/g' common.js
      ln -snf common.js common.min.js

      cd ../..
      sed -i 's,// Check for invalid (control) characters,return true;,g' program/lib/Roundcube/rcube_utils.php
    '';
  });
in {
  ### interface

  options = {
    services.roundcubedev = {
      enable = mkOption {
        default = false;
        description = "Enable roundcube, by providing it to nginx.";
      };

      smtpServer = mkOption {
        default = "localhost";
        description = "The smtp server name";
      };

      smtpPort = mkOption {
        default = 25;
        description = "The smtp port";
      };

      dataDir = mkOption {
        default = "/var/data/roundcube";
        description = "The directory to store roundcube data (i.e. sqlite db file)";
      };

      productName = mkOption {
        default = "Roundcube Webmail";
        description = "A short string displayed on the login page.";
      };

      supportUrl = mkOption {
        default = "/";
        description = "Where a user can get support for this roundcube installation";
      };

      hostName = mkOption {
        example = "webmail.example.com";
        description = "The <literal>server_name</literal> directive for roundcube.";
      };
    };
  };

  ### implementation

  config = mkIf config.services.roundcubedev.enable {
    services.nginx = {
      virtualHosts = {
        ${cfg.hostName} = {
          locations."/" = {
            root = myroundcube;
            index = "index.php";
            extraConfig = ''
              location ~* \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:${fpm.socket};
                include ${pkgs.nginx}/conf/fastcgi_params;
                include ${pkgs.nginx}/conf/fastcgi.conf;
              }
            '';
          };
        };
      };
    };

    services.phpfpm.pools.roundcubedev = {
      user = "nginx";
      phpOptions = ''
        error_log = 'stderr'
        log_errors = on
        post_max_size = 25M
        upload_max_filesize = 25M
      '';
      settings = mapAttrs (name: mkDefault) {
        "listen.owner" = "nginx";
        "listen.group" = "nginx";
        "listen.mode" = "0660";
        "pm" = "dynamic";
        "pm.max_children" = 75;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 20;
        "pm.max_requests" = 500;
        "catch_workers_output" = true;
      };
    };
    systemd.services.phpfpm-roundcubedev.after = ["roundcubedev-setup.service"];

    environment.etc."roundcube/config.inc.php".text = ''
      <?php

      $config['db_dsnw'] = 'sqlite:///${cfg.dataDir}/rc-data.db';
      $config['imap_host'] = 'localhost';
      $config['imap_auth_type'] = 'LOGIN';
      $config['imap_cache'] = 'db';
      $config['smtp_host'] = '${cfg.smtpServer}';
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';
      $config['smtp_port'] = ${builtins.toString cfg.smtpPort};
      $config['product_name'] = '${cfg.productName}';
      $config['des_key'] = '$RC_KEY';
      $config['plugins'] = array('archive', 'zipdownload');
      $config['log_driver'] = 'syslog';
      $config['enable_installer'] = false;
      $config['support_url'] = '${cfg.supportUrl}';
      $config['language'] = 'en_US';
      $config['timezone'] = "Europe/Berlin";
      $config['prefer_html'] = false;
      $config['min_refresh_interval'] = 600;
      $config['max_message_size'] = '25M';
      $config['mime_types'] = RCUBE_INSTALL_PATH . 'config/mime.types';
    '';

    systemd.services.roundcubedev-setup = {
      wantedBy = ["multi-user.target"];
      script = ''
        mkdir -p ${cfg.dataDir}
        if [ ! -f ${cfg.dataDir}/db-created ]; then
            ${pkgs.sqlite}/bin/sqlite3 ${cfg.dataDir}/rc-data.db < ${pkgs.roundcube}/SQL/sqlite.initial.sql
            touch ${cfg.dataDir}/db-created
        fi
        #sqlite requires containing folder to have write permission
        chown -R nginx:nginx ${cfg.dataDir}

        ${pkgs.php}/bin/php ${pkgs.roundcube}/bin/update.sh
      '';
      serviceConfig.Type = "oneshot";
    };
  };
}

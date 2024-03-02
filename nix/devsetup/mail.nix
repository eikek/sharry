{
  config,
  lib,
  pkgs,
  ...
}:
#
# Creates SMTP (exim) and IMAP (dovecot) both withount authentication,
# accepting any user and password. Dovecot creates users on demand on
# the server. If you want to send mail from user a to b, then just
# login both accounts once so dovecot can create the folders.
#
# It then installs roundcube for conveniently accessing mails. It is
# meant to support development of software/scripts that interact with
# mail.
#
let
  checkPassword = ''
    #!/bin/sh

    REPLY="$1"
    INPUT_FD=3
    ERR_FAIL=1
    ERR_NOUSER=3
    ERR_TEMP=111

    read -d ''$'\x0' -r -u $INPUT_FD USER
    read -d ''$'\x0' -r -u $INPUT_FD PASS

    [ "$AUTHORIZED" != 1 ] || export AUHORIZED=2

    if [ "$CREDENTIALS_LOOKUP" = 1 ]; then
      exit $ERR_FAIL
    else
      if [ "$USER" == "$PASS" ]; then
        exec $REPLY
      else
        exit $ERR_FAIL
      fi
    fi
  '';
  checkpasswordScript = pkgs.writeScript "checkpassword-dovecot.sh" checkPassword;
  usersdir = "/var/data/devmail/users";
  cfg = config.services.devmail;
in
  with lib; {
    imports = [./roundcube.nix];

    options = {
      services.devmail = {
        enable = mkOption {
          default = false;
          description = "Enable devmail. This enables exim, dovecot, nginx with roundcube.";
        };

        localDomains = mkOption {
          type = types.listOf types.str;
          description = "List of local domains configured for exim (besides the primaryHostname).";
          default = ["localhost"];
        };

        primaryHostname = mkOption {
          type = types.str;
          description = "The primary domain configured for exim and the nginx virtual server running roundcube.";
          default = "devmail";
        };
      };
    };

    config = mkIf config.services.devmail.enable {
      networking.firewall = {
        allowedTCPPorts = [25 143 80];
      };

      users.groups.exim = {
        name = pkgs.lib.mkForce "exim";
      };
      users.users.exim = {
        description = pkgs.lib.mkForce "exim";
        group = pkgs.lib.mkForce "exim";
        name = pkgs.lib.mkForce "exim";
      };

      environment.systemPackages = [pkgs.inetutils pkgs.sqlite];

      services.nginx.enable = true;
      services.roundcubedev = {
        enable = true;
        hostName = cfg.primaryHostname;
      };

      systemd.tmpfiles.rules = [
        "d /var/spool/exim 1777 exim exim 10d"
      ];

      services.exim = let
        names = [cfg.primaryHostname "@"] ++ cfg.localDomains;

        # https://jimbobmcgee.wordpress.com/2020/07/29/de-tainting-exim-configuration-variables/
        detaintFile = pkgs.writeText "exim-detaint-hack" "*";
      in {
        enable = true;
        config = ''
          primary_hostname = ${cfg.primaryHostname}
          domainlist local_domains = ${builtins.concatStringsSep ":" names}

          acl_smtp_rcpt = acl_check_rcpt
          acl_smtp_data = acl_check_data
          never_users = root

          daemon_smtp_ports = 25 : 587

          split_spool_directory = true
          host_lookup =

          tls_advertise_hosts =
          message_size_limit = 30m

          DETAINTFILE = ${detaintFile}

          begin acl
          acl_check_rcpt:
          accept  authenticated = *
          #accept hosts = :
          #accept

          acl_check_data:
          accept

          begin routers
          localuser:
            driver = accept
            transport = local_delivery
            router_home_directory =
            set = r_safe_local_part=''${lookup{$local_part} lsearch*,ret=key{DETAINTFILE}}
            cannot_route_message = Unknown user


          begin transports
          remote_smtp:
            driver = smtp
            hosts_try_prdr = *

          local_delivery:
            driver = appendfile
            current_directory = ${usersdir}
            maildir_format = true
            directory = ${usersdir}/$r_safe_local_part/Maildir
            delivery_date_add
            envelope_to_add
            return_path_add
            create_directory
            directory_mode = 0755
            mode = 0660
            user = exim
            group = exim

          address_pipe:
            driver = pipe
            return_output

          begin retry
          # Address or Domain    Error       Retries
          # -----------------    -----       -------
          *                      *           F,2h,15m; G,16h,1h,1.5; F,4d,6h

          begin rewrite

          begin authenticators
          PLAIN:
            driver                  = plaintext
            server_set_id           = $auth2
            server_prompts          = :
            server_condition        = ''${if eq{$auth3}{$auth2}}
            server_advertise_condition = true

          LOGIN:
            driver = plaintext
            public_name = LOGIN
            server_prompts = User Name : Password
            server_condition = ''${if eq{$auth1}{$auth2}}
            server_set_id = $auth1

        '';
      };

      services.dovecot2 = {
        enable = true;
        enableImap = true;
        mailLocation = "maildir:${usersdir}/%n/Maildir";
        mailUser = "exim";
        mailGroup = "exim";
        enablePAM = false;
        extraConfig = ''
          first_valid_uid = 172
          userdb {
            driver = static
            args = uid=exim gid=exim home=${usersdir}/%u
          }
          passdb {
            driver = checkpassword
            args = ${checkpasswordScript}
          }
        '';
      };

      systemd.services.devmail-setup = {
        wantedBy = ["multi-user.target"];
        script = ''
          mkdir -p ${usersdir}
          chown -R exim:exim ${usersdir}
        '';
        serviceConfig.Type = "oneshot";
      };
    };
  }

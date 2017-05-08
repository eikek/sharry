# then create a container with nixops (only first time)
#    nixops create -d sharry deploy.nix
#
# first build the app
#    sbt assembly
#
# start it
#    nixops deploy -d sharry
#
# connect your browser to the ip address of the container
#
{
  network.description = "Test Sharry";

  sharry =
    { config, pkgs, ... }:
    let
      sharry = pkgs.stdenv.mkDerivation rec {
        name = "sharry-${version}";
        version = "0.0.1-SNAPSHOT";
        src = ./modules/server/target/scala-2.12/sharry-server-0.0.1-SNAPSHOT.jar.sh;
        unpackPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/sharry-server
          chmod 755 $out/bin/sharry-server
          cat > $out/bin/sharry <<-EOF
          #!/usr/bin/env bash
          export SHARRY_JAVA_OPTS="-Dsharry.authc.extern.admin.enable=true -Dsharry.web.baseurl=http://10.233.1.2/"
          export PATH=${pkgs.jre}/bin:$PATH
          $out/bin/sharry-server
          EOF
          chmod 755 $out/bin/sharry
        '';
      };
      dataDir = "/var/run/sharry";
    in
    {

      networking = {
        firewall = {
          allowedTCPPorts = [ 9090 80 ];
        };
      };

      environment.systemPackages = [sharry];

      users.extraGroups = pkgs.lib.singleton {
        name = "sharry";
      };

      users.extraUsers = pkgs.lib.singleton {
        name = "sharry";
        extraGroups = ["sharry"];
      };

      systemd.services.sharry = {
        description = "sharry service";
        after = [ "networking.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          if [ ! -d "${dataDir}" ]; then
            mkdir -p ${dataDir}
            chown sharry:sharry ${dataDir}
          fi
        '';

        script = ''
          ${pkgs.su}/bin/su -s ${pkgs.bash}/bin/sh sharry -c "cd ${dataDir} && ${sharry}/bin/sharry"
        '';
      };

      services.nginx = {
        enable = true;
        httpConfig = ''
         server {
           listen 0.0.0.0:80;

           proxy_request_buffering off;
           proxy_buffering off;

           location / {
              proxy_pass http://127.0.0.1:9090;
              # this is important, because fs2-http can only do 1.1
              # and it effectively disables request_buffering
              proxy_http_version 1.1;
              proxy_read_timeout  120;
           }
         }
        '';
      };

      deployment.targetEnv = "container";
    };
}

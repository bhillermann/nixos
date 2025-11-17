{ 
  config, 
  lib, 
  pkgs, 
  inputs, 
  ... 
}:


let
  postgresUser = "gisuser";
  postgresPassword = "'$(cat ${config.services.onepassword-secrets.secretPaths."postgisPassword"})'";
  postgresDb = "gisdb";
  dataDir = "/home/brendon/Development/docker-builds/postgis/data/postgis";
in {

  options = {
    postgis = {
      enable = lib.mkOption {
        description = "Enable postgis as a podman systemd service.";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.postgis.enable {

    systemd.user.services.postgis = {
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.podman}/bin/podman run --rm --name postgis \
          -p 5432:5432 \
          -v ${dataDir}:/var/lib/postgresql/data \
          -e POSTGRES_USER=${postgresUser} \
          -e POSTGRES_PASSWORD=${postgresPassword} \
          -e POSTGRES_DB=${postgresDb} \
          docker.io:postgis/postgis";
        Restart = "always";
      };
    };


  };
}

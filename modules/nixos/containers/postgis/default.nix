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

    virtualisation.oci-containers.containers = {
      postgis-db = {
        image = "docker.io/postgis/postgis"; # Example: official PostGIS image
        autoStart = true;
        environment = {
          POSTGRES_DB = "${postgresDb}";
          POSTGRES_USER = "${postgresUser}";
          POSTGRES_PASSWORD = "${postgresPassword}";
        };
        ports = [ "5432:5432" ];
        volumes = [ "${dataDir}:/var/lib/postgresql/data" ];
        podman.user = "nobody";
      };
    };

  };
}

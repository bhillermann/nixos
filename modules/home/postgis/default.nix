{ 
  config, 
  lib, 
  pkgs, 
  inputs, 
  ... 
}:


let
  postgresUser = "gisuser";
  postgresPassword = "$(cat ${config.home.homeDirectory}/.config/opnix/secrets/postgisPassword)";
  postgresDb = "gisdb";
  dataDir = "${config.home.homeDirectory}/Development/docker-builds/postgis/data/postgis";

  
  startScript = pkgs.writeShellScript "start-postgis" ''
    ${pkgs.busybox}/bin/echo PATH=$PATH
    exec ${pkgs.podman}/bin/podman run --replace --name postgis \
      -p 5432:5432 \
      -qv ${dataDir}:/var/lib/postgresql/data \
      -e POSTGRES_USER=${postgresUser} \
      -e POSTGRES_PASSWORD="$(${pkgs.coreutils}/bin/cat /home/brendon/.config/opnix/secrets/postgisPassword)" \
      -e POSTGRES_DB=${postgresDb} \
      docker.io/postgis/postgis
  '';

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
      Unit = {
        Description = "Postgis container for GIS work.";
      };
      Service = {
        Environment = "PATH=$PATH:/run/wrappers/bin";
        ExecStart = "${startScript}";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

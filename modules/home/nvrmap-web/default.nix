{ config, lib, pkgs, inputs, ... }:

let
  nvrmapConfigPath = "${config.home.homeDirectory}/.config/nvrmap/";

  postgresUser = "gisuser";
  postgresDb = "gisdb";
  evc_data =
    "/home/brendon/Documents/GIS/Ensym/EVC benchmark data - external use.xlsx";
  project = "Scenario Test";
  collector = "VegLink";
  default_gain_score = 0.22;
  default_habitat_score = 0.4;

  postgresSecretPath =
    "${config.home.homeDirectory}/.config/opnix/secrets/postgisPassword";

  startScript = pkgs.writeShellScript "start-nvrmap-web" ''
    export NVRMAP_CONFIG=${nvrmapConfigPath}
    export NVRMAP_DB_PASSWORD=`${pkgs.coreutils}/bin/cat ${postgresSecretPath}`

    ${pkgs.db-nvrmap}/bin/db-nvrmap --web --production --host 0.0.0.0 --port 8080
  '';
in {
  options = {
    nvrmap-web = {
      enable = lib.mkOption {
        description = "Run db-nvrmap web service on 0.0.0.0";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.nvrmap-web.enable {

    home.file."${nvrmapConfigPath}config.json".text = builtins.toJSON {
      db_connection = {
        db_type = "postgresql+psycopg2";
        username = postgresUser;
        host = "localhost";
        database = postgresDb;
      };
      evc_data = evc_data;
      attribute_table = {
        project = project;
        collector = collector;
        default_gain_score = default_gain_score;
        default_habitat_score = default_habitat_score;
      };
    };

    systemd.user.services.nvrmap-web = {
      Unit = { Description = "Run db-nvrmap web service on 0.0.0.0"; };
      Service = {
        Environment = "PATH=$PATH:/run/wrappers/bin";
        ExecStart = "${startScript}";
        Restart = "always";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}

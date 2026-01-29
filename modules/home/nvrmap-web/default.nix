{ config
, lib
, pkgs
, inputs
, ...
}:

let
  nvrmapConfigPath = ~/.config/nvrmap/;
  postgresSecretPath =
    "${config.services.onepassword-secrets.secretPaths.nvrmap-webPassword}";

  startScript = pkgs.writeShellScript "start-nvrmap-web" ''
    export NVRMAP_CONFIG=${nvrmapConfigPath}
    export NVRMAP_SECRET=`${pkgs.coreutils}/bin/cat ${postgresSecretPath}`

    ${pkgs.db-nvrmap}/bin/db-nvrmap --web --production --host 0.0.0.0 --port 8080
  '';
in
{
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
    systemd.user.services.nvrmap-web = {
      Unit = {
        description = "Run db-nvrmap web service on 0.0.0.0";
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

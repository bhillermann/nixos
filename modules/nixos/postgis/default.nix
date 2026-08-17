{
  config,
  lib,
  pkgs,
  ...
}:

let
  runUser = "brendon";
  uid = config.users.users.${runUser}.uid;
  homeDir = config.users.users.${runUser}.home;

  postgresUser = "gisuser";
  postgresDb = "gisdb";
  dataDir = "${homeDir}/Development/docker-builds/postgis/data/postgis";

  # opnix writes the raw password value here (owner brendon, mode 0600).
  secretPath = config.services.onepassword-secrets.secretPaths.postgisPassword;

  # Dedicated runtime dir for the rendered env-file, kept separate from the
  # container's own /run/postgis RuntimeDirectory to avoid a lifecycle clash.
  envRuntimeDir = "postgis-secrets";
  envFile = "/run/${envRuntimeDir}/env";
in
{
  options = {
    postgis = {
      enable = lib.mkOption {
        description = "Enable postgis as a rootless podman (oci-containers) system service.";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.postgis.enable {

    # Render the bare opnix secret into the KEY=VALUE env-file oci-containers
    # needs, in tmpfs so it never touches the Nix store.
    systemd.services.postgis-secret-env = {
      description = "Render env-file for the postgis container from the opnix secret.";
      after = [ "opnix-secrets.service" ];
      wants = [ "opnix-secrets.service" ];
      before = [ "podman-postgis.service" ];
      requiredBy = [ "podman-postgis.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = runUser;
        RuntimeDirectory = envRuntimeDir;
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = "yes";
      };
      script = ''
        umask 077
        printf 'POSTGRES_PASSWORD=%s\n' "$(${pkgs.coreutils}/bin/cat ${secretPath})" > ${envFile}
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.postgis = {
        image = "docker.io/postgis/postgis";
        autoStart = true;

        # Run rootless as brendon; reuses the existing ~/.local/share/containers
        # storage and bind-mounted data dir.
        podman.user = runUser;

        ports = [ "5432:5432" ];
        volumes = [ "${dataDir}:/var/lib/postgresql/data" ];

        # Non-secret config goes inline; the password comes from the env-file.
        environment = {
          POSTGRES_USER = postgresUser;
          POSTGRES_DB = postgresDb;
        };
        environmentFiles = [ envFile ];
      };
    };
  };
}

{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

{
  imports = [ ../brendon/core.nix ];

  home.sessionVariables = {
    MS_APP_ID = "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppID)";
    MS_APP_SECRET = "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppSecret)";
    MS_TENANT_ID = "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msTenantID)";
  };

  # Enable OpNix for Home Manager
  programs.onepassword-secrets = {
    secrets = {
      msTenantID = {
        reference = "op://nixos-services/o365_app_credentials/tenant_id";
        path = "/mnt/shares/contact_db/secrets/msTenantID";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
      msAppID = {
        reference = "op://nixos-services/o365_app_credentials/app_id";
        path = "/mnt/shares/contact_db/secrets/msAppID";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
      msAppSecret = {
        reference = "op://nixos-services/o365_app_credentials/app_secret";
        path = "/mnt/shares/contact_db/secrets/msAppSecret";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
    };
  };

  # 1. Define the service that runs your script
  systemd.user.services.nvcr_supply = {
    Unit = {
      Description = "Run weekly maintenance script";
    };
    Service = {
      Type = "oneshot";
      # Automatically creates a shell script inside the Nix store
      ExecStart = "${pkgs.writeShellScript "maintenance-task" ''
        #${pkgs.bash}/bin/bash
        echo "Starting weekly NVCR supply download..."

        ${pkgs.trade-analysis}/bin/title-search --download-nvcr ${config.home.homeDirectory}/NVCR-Data/supply_$(date +%Y%m%d).xlsx

        echo "Download complete."
      ''}";
    };
  };

  # 2. Define the timer that triggers the service weekly
  systemd.user.timers.weekly-maintenance = {
    Unit = {
      Description = "Trigger weekly NVCR supply download";
    };
    Timer = {
      # Triggers every Saturday at midnight
      OnCalendar = "Sat *-*-* 00:00:00";
      # Ensures the script catches up if the machine was turned off during the scheduled time
      Persistent = true;
      Unit = "nvcr_supply.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true;
  programs.claude-code.enable = true;

  # enable nixvim
  nixvim.enable = true;

  postgis.enable = true;

  nvrmap-web.enable = true;

  # Enable vscode-server for this user
  vscode-server.enable = false;

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

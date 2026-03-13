{ lib, pkgs, inputs, config, ... }:

{
  imports = [ ../brendon/core.nix ];

  home.sessionVariables = {
    MS_APP_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppID)";
    MS_APP_SECRET =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppSecret)";
    MS_TENANT_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msTenantID)";
  };

  # Enable OpNix for Home Manager
  programs.onepassword-secrets = {
    secrets = {
      msTenantID = {
        reference = "op://nixos-services/receipt_tracker_api/tenant_id";
        path = "/mnt/shares/contact_db/secrets/msTenantID";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
      msAppID = {
        reference = "op://nixos-services/receipt_tracker_api/username";
        path = "/mnt/shares/contact_db/secrets/msAppID";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
      msAppSecret = {
        reference = "op://nixos-services/receipt_tracker_api/password";
        path = "/mnt/shares/contact_db/secrets/msAppSecret";
        owner = "brendon";
        group = "users";
        mode = "0640";
      };
    };
  };

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true;
  claude-code.enable = true;

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

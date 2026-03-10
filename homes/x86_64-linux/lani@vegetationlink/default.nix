{ lib, pkgs, inputs, config, ... }:

{
  imports = [ ];

  home = {
    username = "lani";
    homeDirectory = "/home/lani";
  };

  programs.bash.enable = true;

  home.sessionVariables = {
    MS_APP_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppID)";
    MS_APP_SECRET =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppSecret)";
    MS_TENANT_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msTenantID)";
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

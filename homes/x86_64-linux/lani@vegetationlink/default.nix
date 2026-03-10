{ lib, pkgs, inputs, config, ... }:

{
  imports = [ ];

  home = {
    username = "brendon";
    homeDirectory = "/home/brendon";
  };

  home.sessionVariables = {
    MS_APP_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppID)";
    MS_APP_SECRET =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msAppSecret)";
    MS_TENANT_ID =
      "$(${pkgs.coreutils}/bin/cat /mnt/shares/contact_db/secrets/msTenantID)";
  };

}

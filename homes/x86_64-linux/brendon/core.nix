{ lib, pkgs, inputs, config, ... }:

{
  imports = [ ];

  home = {
    username = "brendon";
    homeDirectory = "/home/brendon";
  };

  # Enable OpNix for Home Manager
  programs.onepassword-secrets = {
    enable = true;

    secrets = {
      postgisPassword = {
        reference = "op://nixos-services/postgis/password";
        path = ".config/opnix/secrets/postgisPassword";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
      githubToken = {
        reference = "op://nixos-services/github-cli-token/password";
        path = ".config/opnix/secrets/githubToken";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
      sshPrivateKey = {
        reference =
          "op://nixos-services/nixos-wsl-ssh-private/private key?ssh-format=openssh";
        path = ".ssh/id_ed25519";
        mode = "0600";
      };
      msTenantID = {
        reference = "op://nixos-services/receipt_tracker_api/tenant-id";
        path = ".config/opnix/secrets/msTenantID";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
      msAppID = {
        reference = "op://nixos-services/receipt_tracker_api/username";
        path = ".config/opnix/secrets/msAppID";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
      msAppSecret = {
        reference = "op://nixos-services/receipt_tracker_api/password";
        path = ".config/opnix/secrets/msAppSecret";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
    };
  };

}

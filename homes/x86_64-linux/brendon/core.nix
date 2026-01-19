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
      sshPrivateKey = {
        reference =
          "op://nixos-services/nixos-wsl-ssh-private/private key?ssh-format=openssh";
        path = ".ssh/id_ed25519";
        mode = "0600";
      };
    };
  };

}

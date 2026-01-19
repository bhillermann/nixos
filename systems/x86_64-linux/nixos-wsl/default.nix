{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ];

  boot.kernelParams =
    [ "cgroup_no_v1=all" "systemd.unified_cgroup_hierarchy=1" ];

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };

  time.timeZone = "Australia/Melbourne";

  environment.systemPackages = with pkgs; [
    git
    wget
    podman
    podman-compose
    opnix
    su
  ];

  programs.nix-ld = { enable = true; };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/brendon/.nixos";
  };

  services.wslWinhost.enable = true;

  podman.enable = true;

  # Set the default editor to vim
  environment.variables.EDITOR = "nvim";

  # Enable ZSH for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Add user 'brendon'
  users.users.brendon = {
    isNormalUser = true;
    description = "Brendon Hillermann";
    extraGroups = [ "networkmanager" "wheel" "podman" "onepassword-secrets" ];
    linger = true;
    uid = 1000;
  };

  # Enable 1password cli
  programs._1password.enable = true;

  # Enable OpNix for NixOS
  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    secrets = {
      postgisPassword = {
        reference = "op://nixos-services/postgis/password";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
    };
  };

  wsl.enable = true;
  wsl.defaultUser = "brendon";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

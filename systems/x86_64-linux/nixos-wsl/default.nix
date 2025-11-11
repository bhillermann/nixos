# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ 
  config, 
  lib, 
  pkgs, 
  inputs, 
  ... 
}:

{
  imports = [
  ];

  boot.kernelParams = [ "cgroup_no_v1=all" "systemd.unified_cgroup_hierarchy=1" ];

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = ["@wheel"];
  };

  time.timeZone = "Australia/Melbourne";

  environment.systemPackages = with pkgs; [ 
    git
    wget
    podman
    podman-compose
    db-nvrmap
    llama-cpp
  ];

  programs.nix-ld = {
    enable = true;
    # package = pkgs.nix-ld-rs; # only for NixOS 24.05
  };

  # Container configuration
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      # dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/brendon/.nixos";
  };

  services.wslWinhost.enable = true;

  # Set the default editor to vim
  environment.variables.EDITOR = "nvim";

  # Enable ZSH for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Add user 'brendon'
  users.users.brendon = {
    isNormalUser = true;
    description = "Brendon Hillermann";
    extraGroups = [ "networkmanager" "wheel" ];
    linger = true;
    uid = 1000;
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

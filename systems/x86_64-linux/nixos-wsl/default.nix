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

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = ["@wheel"];
  };

 environment.systemPackages = with pkgs; [ 
    wget
  ];

  programs.nix-ld = {
    enable = true;
    # package = pkgs.nix-ld-rs; # only for NixOS 24.05
  };

  services.wslWinhost.enable = true;

  # Set the default editor to vim
  environment.variables.EDITOR = "vim";

  # Enable ZSH for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Add user 'brendon'
  users.users.brendon = {
    isNormalUser = true;
    description = "Brendon Hillermann";
    extraGroups = [ "networkmanager" "wheel" ];
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

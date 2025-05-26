{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";


   # home-manager, user for managing user configuration
   home-manager = {
     url = "github:nix-community/home-manager/release-24.11";
     inputs.nixpkgs.follows = "nixpkgs";
   };

    # nixvim: configure neovim in nix
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snowfall-lib for modularising nix config
    snowfall-lib = { 
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
    };
}


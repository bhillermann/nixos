{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";


   # home-manager, user for managing user configuration
   home-manager = {
     url = "github:nix-community/home-manager/release-25.05";
     inputs.nixpkgs.follows = "nixpkgs";
   };

    # nixvim: configure neovim in nix
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snowfall-lib for modularising nix config
    snowfall-lib = { 
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # stylix: system level theming for nix
    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # db-nvrmap install
    db-nvrmap = {
      url = "git+ssh://git@github.com/bhillermann/db-ensym.git?ref=main";
    };

  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
      
      # Add a module to a specific host.
      systems.hosts.nixos-wsl.modules = with inputs; [
	      nixos-wsl.nixosModules.default
      ];

      channels-config = {
      # Allow unfree packages.
	      allowUnfree = true;
      };
      
    };
}


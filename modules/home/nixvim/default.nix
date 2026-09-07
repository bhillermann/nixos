{
  lib,
  pkgs,
  config,
  ...
}:

{
  options = {
    nixvim = {
      enable = lib.mkOption {
        description = "Enable NixVim.";
        type = lib.types.bool;
        default = false;
      };
      wsl = lib.mkOption {
        description = "Enable WSL-specific clipboard (win32yank).";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.nixvim.enable {

    # NVIM setup
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;

      # Host pkgs sets allowUnfree, which transparent.nvim requires; nixvim's
      # own bare nixpkgs does not.
      nixpkgs.useGlobalPackages = true;

      opts = {
        completeopt = [
          "menu"
          "menuone"
          "noselect"
        ];
        termguicolors = true;
        number = true; # Show line numbers
        relativenumber = true; # Relative line numbers
        shiftwidth = 2; # Tab width
        tabstop = 2;
        expandtab = true; # Spaces instead of tabs
        smartindent = true;
        clipboard = "unnamedplus";
      };

      globals.clipboard = lib.mkIf config.nixvim.wsl {
        name = "win32yank-wsl";
        copy = {
          "+" = [
            "win32yank.exe"
            "-i"
            "--crlf"
          ];
          "*" = [
            "win32yank.exe"
            "-i"
            "--crlf"
          ];
        };
        paste = {
          "+" = [
            "win32yank.exe"
            "-o"
            "--lf"
          ];
          "*" = [
            "win32yank.exe"
            "-o"
            "--lf"
          ];
        };
        cache_enabled = 0;
      };

      colorschemes.catppuccin.enable = true;
    };
  };
}

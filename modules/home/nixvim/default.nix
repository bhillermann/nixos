{ lib, pkgs, config, ... }:

{
  options = {
    nixvim = {
      enable = lib.mkOption {
        description = "Enable NixVim.";
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

      opts = {
        number = true;
        shiftwidth = 2;
        completeopt = [ "menu" "menuone" "noselect" ];
        termguicolors = true;
      };

      colorschemes.catppuccin.enable = true;
      plugins.lualine.enable = true;
      plugins.guess-indent.enable = false;
    };
  };
}

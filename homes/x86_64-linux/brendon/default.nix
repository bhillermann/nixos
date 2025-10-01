{
lib, pkgs, inputs, config, hostname, ...}: 

let
  hostname = config._module.args.hostname or null;
in

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./../../../nixvimPlugins/cmp.nix
    ./../../../nixvimPlugins/copilot.nix
    ./../../../nixvimPlugins/formatter_linter.nix
    ./../../../nixvimPlugins/luasnip.nix
    ./../../../nixvimPlugins/preview.nix
    ./../../../nixvimPlugins/telescope.nix
    ./../../../nixvimPlugins/comment.nix
    ./../../../nixvimPlugins/emmet.nix
    ./../../../nixvimPlugins/nvim_ui.nix
    ./../../../nixvimPlugins/syntax_color_highlight.nix
    ./../../../nixvimPlugins/lsp.nix
    ./../../../nixvimPlugins/git.nix
    ./../../../nixvimPlugins/keymaps.nix
  ];

  home.username = "brendon";
  home.homeDirectory = "/home/brendon";

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true; 

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

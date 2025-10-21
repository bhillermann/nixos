{ lib, pkgs, inputs, config, ...}: 


{
  imports = [
  ];

  home.username = "brendon";
  home.homeDirectory = "/home/brendon";

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true; 

  # enable nixvim
  nixvim.enable = true;

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

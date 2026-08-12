{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

{
  imports = [ ../brendon/core.nix ];

  home.sessionVariables = {
    NVRMAP_CONFIG = "/home/brendon/.config/nvrmap/";
    NVRMAP_DB_PASSWORD = "$(${pkgs.coreutils}/bin/cat /home/brendon/.config/opnix/secrets/postgisPassword)";
  };

  home.packages = with pkgs; [
    geodiff
    trade-analysis
    db-nvrmap
    nodejs_24
    gsd-pi
  ];

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true;

  # CLI harnesses — installation is independent of GSD.
  programs.claude-code.enable = true;
  programs.codex.enable = true;

  # Personal Claude Code settings. These are the top override layer: they win
  # over GSD's installed settings.json and gsd-core's base defaults.
  programs.claude-code.settings = {
    model = "claude-opus-4-6[1m]";
    tui = "fullscreen";
    statusLine = {
      type = "command";
      command = "/bin/bash ${config.home.homeDirectory}/.claude/statusline-command.sh";
    };
    enabledPlugins = {
      "statusline@cc-marketplace" = true;
    };
  };

  # GSD files, per tool (each requires the matching programs.<tool>.enable above).
  gsd-core.claude-code.enable = true;
  gsd-core.codex.enable = true;
  gsd-browser.enable = true;

  # enable nixvim
  nixvim.enable = true;

  # Enable vscode-server for this user
  vscode-server.enable = false;

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

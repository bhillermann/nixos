{ lib, pkgs, config, inputs, ... }:

let cfg = config.claude-code-gsd;
in {
  options = {
    claude-code.enable = lib.mkEnableOption "Claude Code CLI tool";
    claude-code-gsd.enable = lib.mkEnableOption "Claude Code GSD integration";
  };

  config = lib.mkMerge [
    (lib.mkIf config.claude-code.enable {
      home.packages = [ pkgs.claude-code ];
    })

    (lib.mkIf config.claude-code-gsd.enable {
      home.file.".claude" = {
        source = pkgs.gsd-core-claude;
        recursive = true;
      };
    })

  ];
}

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

    (lib.mkIf cfg.enable {
      home.file = {
        ".claude/commands/gsd" = {
          source = "${inputs.gsd}/commands/gsd";
          recursive = true;
        };
        ".claude/get-shit-done" = {
          source = "${inputs.gsd}/get-shit-done";
          recursive = true;
        };
        ".claude/agents" = {
          source = "${inputs.gsd}/agents";
          recursive = true;
        };
      } // lib.optionalAttrs (builtins.pathExists "${inputs.gsd}/hooks") {
        ".claude/hooks" = {
          source = "${inputs.gsd}/hooks";
          recursive = true;
        };
      };
    })
  ];
}

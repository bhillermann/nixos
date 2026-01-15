{ lib, pkgs, config, ... }:

{
  options = {
    claude-code = {
      enable = lib.mkOption {
        description = "Enable Claude Code cli tool.";
        type = lib.types.bool;
        default = false;
      };
    };

  };

  config = lib.mkIf config.claude-code.enable {
    home.packages = with pkgs; [ claude-code ];
  };
}

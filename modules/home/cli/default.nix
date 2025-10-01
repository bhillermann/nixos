{ lib, pkgs, config, ... }:

let 
  cfg = config.pony;
in

{
  options = {
    pony.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Module to enable ponysay";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ponysay
    ];
  };
}

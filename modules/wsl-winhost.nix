{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.wslWinhost;
in {
  options.services.wslWinhost = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the wsl-winhost service.";
    };

    hostnameSuffix = mkOption {
      type = types.str;
      default = "local";
      description = "Suffix to append to hostname for /etc/hosts entry.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "wsl-winhost" ''
        winip=$(${pkgs.coreutils}/bin/grep nameserver /etc/resolv.conf | ${pkgs.coreutils}/bin/awk '{ print $2 }')
        host=$(${pkgs.hostname}/bin/hostname).${cfg.hostnameSuffix}
        if ! ${pkgs.coreutils}/bin/grep -qP "[[:space:]]$winip" /etc/hosts; then
          echo "$winip    $host" >> /etc/hosts
        fi
      '')
    ];

    systemd.services.wsl-winhost = {
      description = "Add Windows host entry to /etc/hosts";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScriptBin "wsl-winhost" ''...''}/bin/wsl-winhost";
      };
    };
  };
}


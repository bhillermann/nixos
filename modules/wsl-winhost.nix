{ pkgs }:

pkgs.writeShellScriptBin "wsl-winhost" ''
  winip=$(${pkgs.coreutils}/bin/grep nameserver /etc/resolv.conf | ${pkgs.coreutils}/bin/awk '{ print $2 }')
  host=$(${pkgs.hostname}/bin/hostname).local
  if ! ${pkgs.coreutils}/bin/grep -qP "[[:space:]]$winip" /etc/hosts; then
    echo "$winip    $host" >> /etc/hosts
  fi
''


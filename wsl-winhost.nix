{ pkgs };

pkgs.writeShellScriptBin "wsl-winhost" ''
  export winip=$(${pkgs.cat}/bin/cat /etc/resolv.conf | ${pkgs.grep}/bin/grep nameserver | ${pkgs.gawk}/bin/awk '{ print $2 }')
''

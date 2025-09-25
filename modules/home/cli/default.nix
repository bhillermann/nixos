{ options, config, lib, pkgs, ... }:

{
    options = {
        core = {
            enable = lib.mkEnableOption {
                description = "Enable core CLI tools.";
                type = lib.types.bool;
                default = false;
        };
    };

    config = lib.mkIf config = {
        core.enable {
            home.packages = with pkgs; [
                fastfetch
                nnn # terminal file manager

                # archives
                zip
                xz
                unzip
                p7zip

                # utils
                ripgrep # recursively searches directories for a regex pattern
                eza # A modern replacement for ‘ls’
                fzf # A command-line fuzzy finder
                bat # A better replacement for cat
                thefuck # Autocorrect cli
                zoxide # A better replacement for cd

                # networking tools
                mtr # A network diagnostic tool
                iperf3
                dnsutils # `dig` + `nslookup`
                ldns # replacement of `dig`, it provide the command `drill`
                aria2 # A lightweight multi-protocol & multi-source command-line download utility
                socat # replacement of openbsd-netcat
                nmap # A utility for network discovery and security auditing
                ipcalc # it is a calculator for the IPv4/v6 addresses

                # misc
                cowsay
                lolcat
                file
                which
                tree
                gnused
                gnutar
                gawk
                zstd
                gnupg

                btop # replacement of htop/nmon
                iotop # io monitoring
                iftop # network monitoring

                # system call monitoring
                strace # system call monitoring
                ltrace # library call monitoring
                lsof # list open files

                # system tools
                sysstat
                lm_sensors # for `sensors` command
                ethtool
                pciutils # lspci
                usbutils # lsusb
            ];
        };
    };

}
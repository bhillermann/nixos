# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, ... }:

let
  postgresUser = "gisuser";
  postgresSecretPath =
    "${config.services.onepassword-secrets.secretPaths.postgisPassword}";
  postgresDb = "gisdb";
  postgresHost = "localhost";

  landowner_script = pkgs.writeShellScript "landowner_script" ''
    #!${pkgs.bash}/bin/bash
    ${pkgs.coreutils}/bin/echo "Hello Landowners!"
    export NVRMAP_DB_TYPE=postgresql+psycopg2
    export NVRMAP_DB_USER=${postgresUser}
    export NVRMAP_DB_PASSWORD=`${pkgs.coreutils}/bin/cat ${postgresSecretPath}`
    export NVRMAP_DB_HOST=${postgresHost}
    export NVRMAP_DB_NAME=${postgresDb}

    ${pkgs.coreutils}/bin/env
  '';

in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "vegetationlink"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking = {
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = "192.168.128.99";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.128.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # setup nh
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/brendon/.nixos";
  };

  # Enable nix-ls (vscode-server doesn't work as well)
  programs.nix-ld.enable = true;

  # Enable zsh for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # add rclone group
  users.groups.rclone = { };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.brendon = {
    isNormalUser = true;
    description = "Brendon Hillermann";
    extraGroups =
      [ "networkmanager" "wheel" "podman" "onepassword-secrets" "rclone" ];
    shell = pkgs.zsh;
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAB3NzaC1lZDI1NTE5AAAAIIIia4jZ/7YW4d4IGAnYX9hWF2bzvR7rReC8KVg6D3Jr your_email@example.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ0rUMiJZwSg4YeZxXuPuI5Sur5ZJO21EIw+S4CdSGGl azuread\\brendonhillermann@VL-8VW7284"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    db-nvrmap
    rclone
    trade-analysis
    geodiff
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #Enable podman
  podman.enable = true;

  # Enable OpNix for NixOS
  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    secrets = {
      postgisPassword = {
        reference = "op://nixos-services/postgis/password";
        owner = "brendon";
        group = "users";
        mode = "0600";
      };
    };
  };

  # rclone setup 
  ## NB!! You have to manually run rclone config for new builds. rclone.conf has to be writable for all users that need it. put the rclone.conf in the /rclone folder
  ## to setup ssh to the remote server with port forwarding
  ## $ ssh -L localhost:53682:localhost:53682 brendon@192.168.128.99
  ## $ sudo mkdir /rclone
  ## $ sudo rclone --config=/rclone/rclone.conf config
  ## setup CS Docs folder as 'cs-docs'
  ## setup GIS folder as 'gis'

  # sync VegLink Landowner layer from posgis instance to shapefile for others to use
  systemd.timers."landowner_sync" = {
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      Unit = "landowner_sync.service";
    };
    enable = true;
  };

  systemd.services."landowner_sync" = {
    description =
      "Sync VegLink Landowner layer from posgis instance to shapefile using rclone";
    script = "${landowner_script}";

    serviceConfig = {
      Type = "oneshot";
      User = "brendon";
    };
    enable = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 5432 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}

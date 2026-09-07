# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # use latest kernal package
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-ec7d83b0-dbc5-4e46-acf3-791cccbbc4e9".device = "/dev/disk/by-uuid/ec7d83b0-dbc5-4e46-acf3-791cccbbc4e9";

  systemd.services.greetd.after = [ "plymouth-quit.service" "plymouth-quit-wait.service" ];

  # Enable plymouth
  boot = {
    plymouth.enable = true;
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd.enable = true;
      kernelModules = [ "i915" ];
    };
    kernelParams = [
      "quiet" "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "vt.global_cursor_default=0""quiet"
    ];
  };

  networking.hostName = "lenovo"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      # numtide llm-agents.nix cache — prebuilt claude-code, codex (codex-rs),
      # etc. The flake declares this via nixConfig.extra-substituters, but Nix
      # ignores flake-declared substituters for untrusted invocations, so pin it
      # here to avoid compiling codex from source.
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Enable nh
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3 --no-gcroots";
    flake = "/home/brendon/.nixos";
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # services.desktopManager.plasma6.enable = true;
  programs.noctalia-greeter = {
    enable = true;
  };

  # Niri scrollable tiling Wayland compositor (alternative session in SDDM).
  programs.niri.enable = true;

  # Temporary wrapper to hide niri 'deprecated' ouput until an upstream fix
  programs.niri.package =
  let
    base = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable; 
  in
  (pkgs.symlinkJoin {
    name = "niri-quiet-session";
    paths = [ base ];
    passthru = { inherit (base.passthru) providedSessions; };
    postBuild = ''
      rm $out/bin/niri-session
      sed -e 's|systemctl --user import-environment|& 2>/dev/null|' \
          -e 's|dbus-update-activation-environment --all|& 2>/dev/null|' \
          ${base}/bin/niri-session > $out/bin/niri-session
      chmod +x $out/bin/niri-session
    '';
  }) // {
    inherit (base) cargoBuildNoDefaultFeatures cargoBuildFeatures;
  };

  # Disable niri's polkit service so noctalia can handle it
  systemd.user.services.niri-flake-polkit.enable = false;

  # Noctalia v5 desktop shell for niri.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # Stylix system-wide theming (catppuccin mocha).
  stylix = {
    enable = true;
    image = ../../../assets/space.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";
  };



  # Enable CUPS to print documents.
  services.printing.enable = true;

  # thermal management
  services.thermald.enable = true;

  # Enable power-profiles-daemon (coordinates with Noctalia & KDE)
  services.power-profiles-daemon.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable ZSH for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.nix-ld = {
    enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # Add user 'brendon'
  users.users.brendon = {
    isNormalUser = true;
    description = "Brendon Hillermann";
    extraGroups = [
      "networkmanager"
      "wheel"
      "podman"
      "onepassword-secrets"
    ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    linger = true;
    uid = 1000;
  };


  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    xwayland-satellite
  ];

  # Enable 1Password CLI and GUI
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "brendon" ];
  };

  # Enable OpNix for NixOS
  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    secrets = {
      tailscaleAuth = {
        reference = "op://nixos-services/tailscale_lenovo/password";
        mode = "0640";
      };
    };
  };

  # enable polkit
  security.polkit.enable = true;

  home-manager.backupFileExtension = ".bak";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable tailscale
  services.tailscale = {
    enable = true;
    authKeyFile = "${config.services.onepassword-secrets.secretPaths.tailscaleAuth}";
  };

  # Force tailscaled to start after opnix runs
  systemd.services.tailscaled = {
    after = [ "${config.systemd.services.opnix-secrets.name}.service" ];
    # requires = [ "${config.systemd.services.opnix-secrets.name}.service" ];
  };

  # Open ports in the firewall.
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
    ];
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

 # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}

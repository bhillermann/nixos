# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable facetime camera
  hardware.facetimehd = {
    enable = true;
    withCalibration = true;
  };

  # Power management (MacBookPro11,2): spurious wakes were over-armed wake
  # sources + level-triggered lid wake; "slow resume" was a broadcom-sta stall
  # before the freeze plus serial CPU re-onlining after it.
  #
  # Runs under `set -e` with other modules' hooks appended after, so nothing
  # here may fail. Writes to /proc/acpi/wakeup TOGGLE the named device, hence
  # the state checks. Re-asserted every suspend (driver rebinds re-arm bits).
  powerManagement.powerDownCommands = ''
    {
      # Forensics: a >0 gpe17 delta across sleep means the EC fired during S3.
      echo "macbook-pm: pre-sleep gpe17=$(${pkgs.gawk}/bin/awk '{print $1}' /sys/firmware/acpi/interrupts/gpe17) bat=$(cat /sys/class/power_supply/BAT0/status)" > /dev/kmsg

      # Keyboard wake needs the full chain armed: ACPI XHC1, the xHCI PCI
      # function, and the bus-1 root hub (disabled since install).
      if ${pkgs.gnugrep}/bin/grep -qE "^XHC1[[:space:]].*\*disabled" /proc/acpi/wakeup; then
        echo XHC1 > /proc/acpi/wakeup
      fi
      echo enabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup
      echo enabled > /sys/bus/usb/devices/usb1/power/wakeup

      # PCIe root ports and P0P2 fire spurious wakes; keep them disarmed.
      for src in RP03 RP04 RP05 P0P2; do
        if ${pkgs.gnugrep}/bin/grep -qE "^$src[[:space:]].*\*enabled" /proc/acpi/wakeup; then
          echo "$src" > /proc/acpi/wakeup
        fi
      done

      # Lid wake is level-triggered: suspending with the lid open wakes ~2s
      # later. Disarm LID0 for lid-open suspends (keyboard/power button still
      # wake); resumeCommands re-arms it.
      if ${pkgs.gnugrep}/bin/grep -q open /proc/acpi/button/lid/LID0/state; then
        if ${pkgs.gnugrep}/bin/grep -qE "^LID0[[:space:]].*\*enabled" /proc/acpi/wakeup; then
          echo LID0 > /proc/acpi/wakeup
        fi
      fi

      # Thunderbolt NHI and PEG bridge assert PME on resume with nothing plugged in.
      for dev in 0000:07:00.0 0000:00:01.0; do
        if [ -w "/sys/bus/pci/devices/$dev/power/wakeup" ]; then
          echo disabled > "/sys/bus/pci/devices/$dev/power/wakeup"
        fi
      done

      # broadcom-sta stalls suspend 2.7-21s on an in-flight scan; power the
      # radio down. Escalate to `modprobe -r wl` if the stall returns.
      ${pkgs.util-linux}/bin/rfkill block wifi

      # The kernel re-onlines CPUs serially after S3 (1-4.5s each) before
      # userspace thaws, blocking the lockscreen 12-15s; offline them now so
      # resumeCommands can bring them back after the session is interactive.
      for cpu in /sys/devices/system/cpu/cpu[1-7]; do
        echo 0 > "$cpu/online"
      done
    } || true
  '';

  powerManagement.resumeCommands = ''
    # Post-sleep counterpart of the gpe17 forensics line.
    echo "macbook-pm: post-sleep gpe17=$(${pkgs.gawk}/bin/awk '{print $1}' /sys/firmware/acpi/interrupts/gpe17) bat=$(cat /sys/class/power_supply/BAT0/status)" > /dev/kmsg || true

    # Re-arm LID0 if the pre-sleep hook disarmed it for a lid-open suspend.
    if ${pkgs.gnugrep}/bin/grep -qE "^LID0[[:space:]].*\*disabled" /proc/acpi/wakeup; then
      echo LID0 > /proc/acpi/wakeup || true
    fi

    # Wifi before the CPU loop below, which blocks for seconds.
      echo LID0 > /proc/acpi/wakeup || true
    fi

    # Wifi before the CPU loop below, which blocks for seconds.
    ${pkgs.util-linux}/bin/rfkill unblock wifi || true

    # Each write blocks 1-4.5s; per-CPU || true so one stuck core can't strand the rest.
    for cpu in /sys/devices/system/cpu/cpu[1-7]; do
      echo 1 > "$cpu/online" || true
    done
  '';

  # Per-device suspend/resume timings + PM phase annotations in the journal.
  systemd.services.pm-debug-instrumentation = {
    description = "Enable kernel PM debug timing";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo 1 > /sys/power/pm_print_times
      echo 1 > /sys/power/pm_debug_messages
    '';
  };

  # Haswell thermal management; nothing was driving the passive trip points.
  services.thermald.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.tmp.cleanOnBoot = true;

  networking.hostName = "macbook";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Broadcom Wi-Fi configuration
  # Enable the open-source firmware extractor
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelModules = [ "wl" ];
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "ssb"
    "brcsmac"
    "brcmfmac"
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.12.103"
    "broadcom-sta-6.30.223.271-59-6.12.97"
  ];

  hardware.enableRedistributableFirmware = true;

  services.usbmuxd.enable = true;

  # boot.loader.systemd-boot.configuration = 10;

  # Enable OpNix for NixOS
  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    secrets = {
      tailscaleAuth = {
        reference = "op://nixos-services/tailscale_nerdbox/password";
        mode = "0600";
      };
    };
  };

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
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "brendon" ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  # GitHub PAT for private flake inputs, kept out of git: seed a root-owned
  # 0600 /etc/nix/access-tokens.conf with "access-tokens = github.com=<PAT>".
  # `!include` tolerates the file being absent.
  nix.extraOptions = ''
    !include /etc/nix/access-tokens.conf
  '';

  # Install firefox.
  programs.firefox.enable = true;

  programs.nix-ld = {
    enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3 --no-gcroots";
    flake = "/home/brendon/.nixos";
  };

  # Enable ZSH for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Declared so brendon's extraGroups membership isn't silently dropped; the
  # opnix home-manager module needs group read on /etc/opnix-token.
  users.groups.onepassword-secrets = { };

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
    linger = true;
    uid = 1000;
    packages = with pkgs; [
      kdePackages.kate
      # thunderbird
    ];
  };

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}

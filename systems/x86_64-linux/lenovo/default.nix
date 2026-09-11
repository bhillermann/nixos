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
      "pcie_aspm.policy=powersupersave"
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

  # Sleep on this machine (Yoga Slim 7 Carbon 13ITL5, Tiger Lake, BIOS
  # F7CN41WW): s2idle is entered but the PCH never asserts SLP_S0, so S0ix
  # residency is 0 % and lid-closed sleep drains ~0.9 W (~2 %/h). Verified
  # Sep 2026 on kernels 7.2.0 and 7.2.2 with TBT/USB/WiFi/ISH/DPTF disabled
  # one by one and all together; the firmware publishes no S0ix requirement
  # table and the NVMe root port has no D3cold methods. S3 ("deep") hangs.
  #
  # Mitigation: suspend-then-hibernate. s2idle for HibernateDelaySec, then
  # write the image to the LUKS swap (17 GB > 16 GB RAM) and power off.
  boot.resumeDevice = "/dev/mapper/luks-ec7d83b0-dbc5-4e46-acf3-791cccbbc4e9";
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";

  # Sleep diagnostics: log per-sleep energy and S0ix residency around every
  # suspend and let pmc_core warn when SLP_S0 was not reached.
  #
  # After a sleep, read the verdict with:
  #   journalctl -k | grep -E "lenovo-pm|SLP_S0|S0ix"
  #
  # Runs under `set -e` with other modules' hooks appended after, so nothing
  # here may fail.
  boot.extraModprobeConfig = ''
    # Print "CPU did not enter SLP_S0" plus the blocking PCH IPs on resume
    # when the SLP_S0 residency counter did not advance during the sleep.
    options intel_pmc_core warn_on_s0ix_failures=1
  '';

  # Wakeup-source and PM-phase messages in the journal for every suspend.
  systemd.services.pm-debug-instrumentation = {
    description = "Enable kernel PM debug messages";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wakeup source ("PM: Triggering wakeup from IRQ n") per resume.
      echo 1 > /sys/power/pm_debug_messages
      # modprobe.d only applies at module load; set it live too so a switch
      # without reboot picks it up.
      echo 1 > /sys/module/intel_pmc_core/parameters/warn_on_s0ix_failures || true
      # For deeper digging, per-device D-states at suspend can be had with:
      #   echo 'file drivers/pci/pci-driver.c +p' > /sys/kernel/debug/dynamic_debug/control
      # (drivers/acpi/device_pm.c too, but it logs every touchpad runtime-PM cycle).
    '';
  };

  powerManagement.powerDownCommands = ''
    {
      pmc=/sys/kernel/debug/pmc_core
      slp=$(cat $pmc/slp_s0_residency_usec 2>/dev/null || echo 0)
      energy=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null || echo 0)
      echo "$(date +%s) $energy $slp" > /run/lenovo-pm-presleep
      echo "lenovo-pm: pre-sleep energy_uwh=$energy slp_s0_us=$slp bat=$(cat /sys/class/power_supply/BAT0/status) lid=$(${pkgs.gawk}/bin/awk '{print $2}' /proc/acpi/button/lid/LID0/state)" > /dev/kmsg
      # S0ix substate residencies before sleep (S0i2.x / S0i3.x on Tiger Lake).
      if [ -r $pmc/substate_residencies ]; then
        tail -n +2 $pmc/substate_residencies | while read -r name val; do
          echo "lenovo-pm: pre-sleep $name=$val" > /dev/kmsg
        done
      fi
    } || true
  '';

  powerManagement.resumeCommands = ''
    {
      pmc=/sys/kernel/debug/pmc_core
      slp=$(cat $pmc/slp_s0_residency_usec 2>/dev/null || echo 0)
      energy=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null || echo 0)
      if [ -r /run/lenovo-pm-presleep ]; then
        read t0 e0 s0 < /run/lenovo-pm-presleep
        ${pkgs.gawk}/bin/awk -v t0="$t0" -v t1="$(date +%s)" -v e0="$e0" -v e1="$energy" -v s0="$s0" -v s1="$slp" 'BEGIN {
          dt = t1 - t0; if (dt < 1) dt = 1;
          dwh = (e0 - e1) / 1e6;
          printf "lenovo-pm: post-sleep slept=%dm%02ds used=%.2fWh avg=%.2fW s0ix_residency=%.1f%%\n", dt/60, dt%60, dwh, dwh / (dt/3600), (s1 - s0) / (dt * 1e6) * 100
        }' > /dev/kmsg
      fi
      echo "lenovo-pm: post-sleep energy_uwh=$energy slp_s0_us=$slp bat=$(cat /sys/class/power_supply/BAT0/status)" > /dev/kmsg
      if [ -r $pmc/substate_residencies ]; then
        tail -n +2 $pmc/substate_residencies | while read -r name val; do
          echo "lenovo-pm: post-sleep $name=$val" > /dev/kmsg
        done
      fi
    } || true
  '';

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

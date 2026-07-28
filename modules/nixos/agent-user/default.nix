# modules/nixos/agent-user/default.nix
#
# Dedicated unprivileged POSIX user for AI coding agents (Claude Code, gsd-pi),
# with a shared bare-repo "hub" directory for git-mediated handoff between your
# primary user and the agent. Snowfall-lib auto-discovers this module from
# modules/nixos/agent-user/. If you keep options under your snowfall namespace,
# add `namespace` to the arg set and change `services.agent-user` to
# `${namespace}.services.agent-user` in both places.
#
# Enable in your host config (systems/x86_64-linux/<host>/default.nix):
#
#   services.agent-user = {
#     enable = true;
#     adminUser = "brendon";   # <- your actual username
#   };
#
# One-time bootstrap after `nh os switch` (imperative by design — agent CLIs
# self-update and stay out of your flakes):
#
#   agent-shell                                  # login shell as the agent
#     curl -fsSL https://claude.ai/install.sh | bash
#     npm config set prefix ~/.npm-global
#     echo 'export PATH=~/.npm-global/bin:~/.local/bin:$PATH' >> ~/.bashrc
#     git config --global user.name  "Brendon (agent)"
#     git config --global user.email "you+agent@example.com"
#     claude   # then /login
#
# Daily loop:
#   agent-hub init ~/dev/myproject      # once per project: bare hub + 'hub' remote
#   git push hub main                   # you: publish current state
#   agent-shell                         # work happens as the agent, in its clone
#   git fetch hub && git diff main...hub/agent/<branch>   # you: REVIEW, then merge

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.agent-user;

  agent-hub = pkgs.writeShellApplication {
    name = "agent-hub";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      hub=${lib.escapeShellArg cfg.hubDir}
      group=${lib.escapeShellArg cfg.shareGroup}
      cmd="''${1:-help}"

      case "$cmd" in
        init)
          src="''${2:?usage: agent-hub init /path/to/repo}"
          top="$(git -C "$src" rev-parse --show-toplevel)"
          name="$(basename "$top")"
          bare="$hub/$name.git"

          if [ -e "$bare" ]; then
            echo "already exists: $bare" >&2
            exit 1
          fi

          git clone --bare "$top" "$bare"
          git -C "$bare" config core.sharedRepository group
          chgrp -R "$group" "$bare"
          chmod -R g+rwX "$bare"
          find "$bare" -type d -exec chmod g+s {} +

          if git -C "$top" remote get-url hub >/dev/null 2>&1; then
            git -C "$top" remote set-url hub "$bare"
          else
            git -C "$top" remote add hub "$bare"
          fi

          echo "hub created: $bare"
          echo "remote 'hub' configured in $top"
          echo "next: git push hub main"
          ;;
        list)
          find "$hub" -mindepth 1 -maxdepth 1 -name '*.git' -printf '%f\n'
          ;;
        *)
          echo "usage: agent-hub init /path/to/repo | agent-hub list" >&2
          exit 1
          ;;
      esac
    '';
  };

  agent-shell = pkgs.writeShellApplication {
    name = "agent-shell";
    text = ''
      # -i = clean login environment: none of your exported vars leak in.
      exec sudo -iu ${lib.escapeShellArg cfg.user} "$@"
    '';
  };
in
{
  options.services.agent-user = {
    enable = lib.mkEnableOption "dedicated unprivileged user for AI coding agents";

    user = lib.mkOption {
      type = lib.types.str;
      default = "agent";
      description = "Name of the agent user.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1100;
      description = ''
        Fixed uid for the agent user. Needed so the systemd slice
        (user-<uid>.slice) can be configured declaratively for resource limits.
      '';
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      example = "brendon";
      description = ''
        Your primary user. Gets membership of the share group, a (default) 700
        home mode so the agent cannot read it, and passwordless sudo to the
        agent user.
      '';
    };

    shareGroup = lib.mkOption {
      type = lib.types.str;
      default = "agents";
      description = "Group shared by adminUser and the agent; owns the hub directory.";
    };

    hubDir = lib.mkOption {
      type = lib.types.path;
      default = "/srv/agent-git";
      description = "Directory holding bare hub repositories both users can reach.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages available to the agent user.";
    };

    memoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "8G";
      description = ''
        MemoryMax for the agent's user slice (null to disable). Best-effort on
        WSL2 — requires cgroup v2, which NixOS-WSL with native systemd provides.
      '';
    };

    cpuQuota = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "400%";
      description = "CPUQuota for the agent's user slice, e.g. 400% = 4 cores (null to disable).";
    };

    passwordlessSudo = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow adminUser to run commands as the agent user without a password.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.shareGroup} = { };

    users.users.${cfg.user} = {
      isNormalUser = true;
      uid = cfg.uid;
      description = "AI coding agent";
      homeMode = "700";
      extraGroups = [ cfg.shareGroup ];
      # Deliberately NOT in wheel/podman/docker, and not a nix trusted-user.
      shell = pkgs.bash;
      packages =
        with pkgs;
        [
          nodejs_22
          git
          gh
          ripgrep
          jq
          fd
          vim
        ]
        ++ cfg.extraPackages;
    };

    # The actual wall: the agent can only be locked out of your home if your
    # home isn't world-readable. mkDefault so an explicit setting elsewhere wins.
    users.users.${cfg.adminUser} = {
      extraGroups = [ cfg.shareGroup ];
      homeMode = lib.mkDefault "700";
    };

    # Hub directory: setgid so new bare repos inherit the share group.
    systemd.tmpfiles.rules = [
      "d ${cfg.hubDir} 2770 root ${cfg.shareGroup} -"
    ];

    # Caps everything the agent user runs (sessions land in user-<uid>.slice).
    systemd.slices."user-${toString cfg.uid}" = {
      description = "Resource limits for AI agent user";
      sliceConfig = lib.filterAttrs (_: v: v != null) {
        MemoryMax = cfg.memoryMax;
        CPUQuota = cfg.cpuQuota;
      };
    };

    security.sudo.extraRules = lib.mkIf cfg.passwordlessSudo [
      {
        users = [ cfg.adminUser ];
        runAs = cfg.user;
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    environment.systemPackages = [
      agent-hub
      agent-shell
    ];

    programs.nix-ld.libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd # libudev
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
    ];

  };
}

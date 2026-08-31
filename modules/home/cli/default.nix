{
  lib,
  pkgs,
  config,
  ...
}:

let
  # Definte github CLI token secret for home-manager
  githubTokenSecret = "${config.home.homeDirectory}/.config/opnix/secrets/githubToken";

  # Define vscode-server source for home-manager
  vscode-server-src = pkgs.fetchgit {
    url = "https://github.com/msteen/nixos-vscode-server";
    rev = "7943271335904017d3fafbf6fea395beebe42239";
    sha256 = "sha256-Bx7DOPLhkr8Z60U9Qw4l0OidzHoqLDKQH5rDV5ef59A=";
  };
in
{

  # Import vscode-server for home-manager
  imports = [ "${vscode-server-src}/modules/vscode-server/home.nix" ];

  options = {
    core = {
      enable = lib.mkOption {
        description = "Enable core CLI tools.";
        type = lib.types.bool;
        default = false;
      };
    };

    dev = {
      enable = lib.mkOption {
        description = "Enable additional dev tools.";
        type = lib.types.bool;
        default = false;
      };
    };

    vscode-server = {
      enable = lib.mkOption {
        description = "Enable the vscode-server per user home-configuration";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.core.enable {
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
        eza # A modern replacement for 'ls'
        fzf # A command-line fuzzy finder
        bat # A better replacement for cat
        pay-respects # Autocorrect cli
        zoxide # A better replacement for cd
        nixfmt # needed for nix formatting from vscode

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
        jq

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
        rclone

        # GIS Tools
        gdal
      ];

      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.bat = {
        enable = true;
        themes = {
          catppuccin-mocha = {
            src = pkgs.fetchFromGitHub {
              "owner" = "catppuccin";
              "repo" = "bat";
              "rev" = "699f60fc8ec434574ca7451b444b880430319941";
              "hash" = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
            };
            file = "/themes/Catppuccin Mocha.tmTheme";
          };
        };
        config = {
          theme = lib.mkDefault "catppuccin-mocha";
        };
      };

      programs.fzf.enable = true;

      programs.pay-respects = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.git = {
        enable = true;
        package = pkgs.gitFull;
        settings = {
          user.name = "bhillermann";
          user.email = "bhillermann@gmail.com";
          init.defaultBranch = "main";
          url."git@github.com:".insteadOf = "https://github.com/";
        };
      };

      # GitHub CLI
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };

      # Set GH_TOKEN environment variable for GitHub CLI auth
      home.sessionVariablesExtra = ''
        export GH_TOKEN="$(${pkgs.coreutils}/bin/cat ${githubTokenSecret})"
      '';

      # starship - an customizable prompt for any shell
      programs.starship = {
        enable = true;
        settings = {
          format = "[](red)$os$username$hostname[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:green bg:sapphire)$conda[](fg:sapphire bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";
          palette = "catppuccin_mocha";
          command_timeout = 500;
          scan_timeout = 50;

          line_break.disabled = false;
          git_status.disabled = true;

          os = {
            disabled = false;
            style = "bg:red fg:crust";
          };

          username = {
            format = "[ $user]($style)";
            show_always = true;
            style_root = "bg:red fg:crust";
            style_user = "bg:red fg:crust";
          };

          hostname = {
            format = "[ $hostname]($style)";
            style = "bg:red fg:crust";
            disabled = false;
            ssh_only = true;
            ssh_symbol = "🌐";
          };

          directory = {
            format = "[ $path ]($style)";
            style = "bg:peach fg:crust";
            truncation_length = 3;
          };

          git_branch = {
            format = "[ $branch ]($style)";
            style = "bg:yellow fg:crust";
          };

          time = {
            disabled = false;
            format = "[  $time ]($style)";
            style = "bg:lavender fg:crust";
            time_format = "%R";
          };

          c = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          rust = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          golang = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          nodejs = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          php = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          java = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          kotlin = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          haskell = {
            format = "[ via $symbol($version) ]($style)";
            style = "bg:green fg:crust";
          };

          python = {
            format = "[ via $symbol($version) (\\($virtualenv\\)) ]($style)";
            style = "bg:green fg:crust";
          };

          conda = {
            format = "[ $symbol$environment ]($style)";
            style = "bg:sapphire fg:crust";
          };

          character = {
            success_symbol = "[❯](green)";
            error_symbol = "[❯](red)";
          };

          palettes.catppuccin_mocha = {
            rosewater = "#f5e0dc";
            flamingo = "#f2cdcd";
            pink = "#f5c2e7";
            mauve = "#cba6f7";
            red = "#f38ba8";
            maroon = "#eba0ac";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            sky = "#89dceb";
            sapphire = "#74c7ec";
            blue = "#89b4fa";
            lavender = "#b4befe";
            text = "#cdd6f4";
            subtext1 = "#bac2de";
            subtext0 = "#a6adc8";
            overlay2 = "#9399b2";
            overlay1 = "#7f849c";
            overlay0 = "#6c7086";
            surface2 = "#585b70";
            surface1 = "#45475a";
            surface0 = "#313244";
            base = "#1e1e2e";
            mantle = "#181825";
            crust = "#11111b";
          };
        };
      };

      programs.zsh = {
        enable = true;
        shellAliases = {
          nd = "nix develop";
          ls = "eza --color=always --long --icons=always";
          cd = "z";
          nixr = "sudo nixos-rebuild switch --flake ~/.nixos";
          cat = "bat -pp";
          gsd = "gsd";
        };

        autosuggestion.enable = true;

        sessionVariables = {
          EDITOR = "nvim";
          MANPAGER = "bat -l man -p ";
        };

        # Silence zoxide's "initialize at end of config" doctor nag
        envExtra = ''
          export _ZO_DOCTOR=0
        '';

        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "colorize"
            "cp"
            "vi-mode"
            "last-working-dir"
            "fancy-ctrl-z"
          ];
        };
      };
    })

    (lib.mkIf config.dev.enable {
      home.packages = with pkgs; [
        devenv
      ];

      # nix-direnv
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };
    })

    (lib.mkIf config.vscode-server.enable {
      # enable the systemd service
      services.vscode-server.enable = config.vscode-server.enable;
    })

  ];
}

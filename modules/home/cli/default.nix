{ lib, pkgs, config, ... }:


let
	# Define vscode-server source for home-manager
	vscode-server-src = pkgs.fetchgit  {
		url = "https://github.com/msteen/nixos-vscode-server";
		rev = "7943271335904017d3fafbf6fea395beebe42239";
		sha256 = "sha256-Bx7DOPLhkr8Z60U9Qw4l0OidzHoqLDKQH5rDV5ef59A=";
	};
in
{

	# Import vscode-server for home-manager
	imports = [
		"${vscode-server-src}/modules/vscode-server/home.nix"
	];

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
	    file = "/themes/Catppuccin\ Mocha.tmTheme";
	  };
	};
	config = {
	  theme = "catppuccin-mocha";
	};
      };

      programs.fzf.enable = true;

      programs.thefuck = {
	enable = true;
	enableZshIntegration = true;
      };

      programs.git = {
	enable = true;
	package = pkgs.gitFull;
	# config = {
	#   credential.helper = "libsecret";
	# };
	userName = "bhillermann";
	userEmail = "bhillermann@gmail.com";
	extraConfig = {
	  init.defaultBranch = "main";
	};
      };

      # starship - an customizable prompt for any shell
      programs.starship = {
	enable = true;
	# custom settings
	settings = lib.mkMerge [
	  (builtins.fromTOML
	    (builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml")
	  )
	  {
	    line_break.disabled = lib.mkForce false;

	    format = lib.mkForce "[](red)$os$username$hostname[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:green bg:sapphire)$conda[](fg:sapphire bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";

	    username = lib.mkForce {
	      format = "[ $user]($style)";
	      show_always = true;
	      style_root = "bg:red fg:crust";
	      style_user = "bg:red fg:crust";
	    };

	    hostname = lib.mkForce {
	      format = "[ $hostname]($style)";
	      style = "bg:red fg:crust";
	      disabled = false;
	      ssh_only = true;
	      ssh_symbol = "🌐";
	    };

	  }
	];
      };

      programs.zsh = {
	enable = true;
	shellAliases = {
	  nd = "nix develop";
	  ls = "eza --color=always --long --git --icons=always";
	  cd = "z";
	  nixr = "sudo nixos-rebuild switch --flake ~/.nixos";
	};

	autosuggestion.enable = true;
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
	# devenv - ony trialling this
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
		services.vscode-server.enable = true;
    })

  ];
}

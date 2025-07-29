{
lib, pkgs, inputs, config, hostname, ...}: 

let
  hostname = config._module.args.hostname or null;
in

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./../../../nixvimPlugins/cmp.nix
    ./../../../nixvimPlugins/copilot.nix
    ./../../../nixvimPlugins/formatter_linter.nix
    ./../../../nixvimPlugins/luasnip.nix
    ./../../../nixvimPlugins/preview.nix
    ./../../../nixvimPlugins/telescope.nix
    ./../../../nixvimPlugins/comment.nix
    ./../../../nixvimPlugins/emmet.nix
    ./../../../nixvimPlugins/nvim_ui.nix
    ./../../../nixvimPlugins/syntax_color_highlight.nix
    ./../../../nixvimPlugins/lsp.nix
    ./../../../nixvimPlugins/git.nix
    ./../../../nixvimPlugins/keymaps.nix
  ];

  home.username = "brendon";
  home.homeDirectory = "/home/brendon";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

    neofetch
    nnn # terminal file manager

    # devenv
    devenv

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

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

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

    
  ] ++ lib.optionals (hostname == "lenovo") [
      kdePackages.kate
      stremio
      bottles

    ];

  # NVIM setup
  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    opts = {
      number = true;
      shiftwidth = 2;
      completeopt = [ "menu" "menuone" "noselect" ];
      termguicolors = true;
    };

    colorschemes.catppuccin.enable = true;
    plugins.lualine.enable = true;
    plugins.guess-indent.enable = false;
  };

  # nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

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

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

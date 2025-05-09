{ config, pkgs, ... }:

{
  home.username = "brendon";
  home.homeDirectory = "/home/brendon";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

    neofetch
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
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
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

    btop  # replacement of htop/nmon
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

  # NVIM setup
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    plugins = [
        ## Treesitter
        pkgs.vimPlugins.nvim-treesitter
        pkgs.vimPlugins.nvim-treesitter.withAllGrammars
        pkgs.vimPlugins.nvim-treesitter-textobjects
        pkgs.vimPlugins.nvim-lspconfig

        pkgs.vimPlugins.trouble-nvim
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.telescope-nvim
        pkgs.vimPlugins.telescope-fzf-native-nvim
        pkgs.vimPlugins.fidget-nvim

        ## cmp
        pkgs.vimPlugins.nvim-cmp
        pkgs.vimPlugins.cmp-nvim-lsp
        pkgs.vimPlugins.cmp-buffer
        pkgs.vimPlugins.cmp-cmdline

        pkgs.vimPlugins.clangd_extensions-nvim
        pkgs.vimPlugins.luasnip
        pkgs.vimPlugins.cmp_luasnip
        pkgs.vimPlugins.lspkind-nvim
        pkgs.vimPlugins.nvim-lint
        pkgs.vimPlugins.vim-surround
        pkgs.vimPlugins.vim-obsession
        pkgs.vimPlugins.kommentary
        pkgs.vimPlugins.neoformat
        pkgs.vimPlugins.lazygit-nvim
        pkgs.vimPlugins.gitsigns-nvim
        pkgs.vimPlugins.rainbow
        pkgs.vimPlugins.vim-sleuth
        pkgs.vimPlugins.lualine-nvim
        pkgs.vimPlugins.nvim-web-devicons
        pkgs.vimPlugins.lightspeed-nvim
        pkgs.vimPlugins.leap-nvim
        pkgs.vimPlugins.vim-repeat
        pkgs.vimPlugins.kanagawa-nvim

        ## Debugging
        pkgs.vimPlugins.nvim-dap
        pkgs.vimPlugins.nvim-dap-ui
        pkgs.vimPlugins.nvim-dap-virtual-text
    ];
  };

  # basic configuration of git, please change to your own
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
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  programs.alacritty = {
    enable = true;
    # custom settings
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf.enable = true;

  programs.zsh = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      ls = "eza --color=always --long --git --icons=always";
      cd = "z";
      nixr = "sudo nixos-rebuild switch";
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

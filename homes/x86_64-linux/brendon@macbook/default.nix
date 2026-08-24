{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

{
  imports = [
    ../brendon/core.nix
    inputs.noctalia.homeModules.default
  ];

  home.packages = with pkgs; [
    nodejs_24
    fuzzel
    playerctl
    brightnessctl
    stremio-linux-shell
    vlc
  ];

  # enable core cli packages and settings
  core.enable = true;

  stylix.targets.starship.enable = false;
  stylix.fonts.monospace = {
    package = pkgs.nerd-fonts.jetbrains-mono;
    name = "JetBrainsMono Nerd Font";
  };

  programs.kitty.enable = true;
  programs.alacritty.enable = true;

  # enable extra dev packages and settings
  dev.enable = true;
  programs.claude-code.enable = true;
  gsd-browser.enable = true;
  # Personal Claude Code settings.
  programs.claude-code.settings = {
    model = "claude-opus-4-6[1m]";
    statusLine = {
      type = "command";
      command = "bash ${config.home.homeDirectory}/.claude/statusline-command.sh";
    };
    tui = "fullscreen";
    enabledPlugins = {
      "statusline@cc-marketplace" = true;
    };
  };

  # enable nixvim
  nixvim.enable = true;

  # Niri compositor configuration (keybinds, layout, input, startup).
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "au";
      touchpad = {
        natural-scroll = true;
        tap = false;
        dwt = true;
      };
    };

    layout = {
      gaps = 8;
      center-focused-column = "on-overflow";
      border = {
        enable = true;
        width = 2;
        active.color = lib.mkDefault "#89b4fa";
        inactive.color = lib.mkDefault "#45475a";
      };
      focus-ring.enable = false;
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
    };

    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    environment = {
      NIXOS_OZONE_WL = "1";
      LIBVA_DRIVER_NAME = "i965";
      VDPAU_DRIVER = "va_gl";
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };

    spawn-at-startup = [
      { command = [ "noctalia" ]; }
    ];

    binds = {
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+D".action.spawn = [ "fuzzel" ];
      "Mod+Q".action.close-window = [ ];

      "Mod+H".action.focus-column-left = [ ];
      "Mod+L".action.focus-column-right = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];

      "Mod+Shift+H".action.move-column-left = [ ];
      "Mod+Shift+L".action.move-column-right = [ ];
      "Mod+Shift+J".action.move-window-down = [ ];
      "Mod+Shift+K".action.move-window-up = [ ];

      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];

      "Mod+Space".action.spawn = [ "sh" "-c" "noctalia msg panel-toggle launcher" ];
      "Mod+Shift+Space".action.switch-focus-between-floating-and-tiling = [ ];

      "Mod+Comma".action.consume-window-into-column = [ ];
      "Mod+Period".action.expel-window-from-column = [ ];

      "Mod+Tab".action.toggle-overview = [ ];
      "Mod+I".action.spawn = [ "sh" "-c" ''
        cat <<'BINDS' | fuzzel --dmenu --width=60 --lines=35 --prompt="Keybinds > "
        Super+Return        Open terminal
        Super+D             App launcher
        Super+Space         Panel launcher
        Super+Q             Close window
        Super+H/L           Focus column left/right
        Super+J/K           Focus window down/up
        Super+Shift+H/L     Move column left/right
        Super+Shift+J/K     Move window down/up
        Super+R             Cycle preset column width
        Super+F             Maximize column
        Super+Shift+F       Fullscreen window
        Super+Shift+Space   Toggle floating/tiling focus
        Super+,             Consume window into column
        Super+.             Expel window from column
        Super+Tab           Toggle overview
        Super+I             Show keybinds (this)
        Super+1-9           Focus workspace 1-9
        Super+Shift+1-9     Move column to workspace 1-9
        Super+PageDown/Up   Focus workspace down/up
        Super+Shift+PgDn/Up Move to workspace down/up
        Super+ScrollDown/Up Scroll workspaces
        Super+Shift+E       Quit niri
        Print               Screenshot (region)
        Ctrl+Print          Screenshot (screen)
        Alt+Print           Screenshot (window)
        VolUp/VolDown       Volume ±5%
        Mute                Toggle mute
        Play                Play/pause media
        Next/Prev           Next/previous track
        BrightnessUp/Down   Screen brightness ±5%
        KbdBrightUp/Down    Keyboard backlight ±10%
        BINDS
      '' ];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      "Mod+Page_Down".action.focus-workspace-down = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+Shift+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Shift+Page_Up".action.move-column-to-workspace-up = [ ];

      "Mod+WheelScrollDown" = {
        action.focus-workspace-down = [ ];
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = {
        action.focus-workspace-up = [ ];
        cooldown-ms = 150;
      };

      "Mod+P".action.screenshot = [ ];
      "Mod+Shift+P".action.screenshot-screen = [ ];
      "Mod+Alt+P".action.screenshot-window = [ ];

      "Mod+Shift+E".action.quit = [ ];
      # Media keys
      "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "0.05+" ];
      "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-" ];
      "XF86AudioMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
      "XF86AudioPlay".action.spawn = [ "playerctl" "play-pause" ];
      "XF86AudioNext".action.spawn = [ "playerctl" "next" ];
      "XF86AudioPrev".action.spawn = [ "playerctl" "previous" ];
      "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "5%+" ];
      "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "5%-" ];
      "XF86KbdBrightnessUp".action.spawn = [ "brightnessctl" "-d" "smc::kbd_backlight" "set" "10%+" ];
      "XF86KbdBrightnessDown".action.spawn = [ "brightnessctl" "-d" "smc::kbd_backlight" "set" "10%-" ];
    };
  };

  # Noctalia v5 desktop shell.
  programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
      };
      shell = {
        polkit_agent = true;
        clipboard_enabled = true;
      };
      bar.main = {
        position = "top";
        thickness = 34;
        start = [ "launcher" "workspaces" ];
        center = [ "clock" ];
        end = [
          "tray"
          "volume"
          "battery"
          "network"
          "notifications"
          "control-center"
        ];
      };
      notification.daemon = true;
      lockscreen.enabled = true;
    };
  };

  # Enable vscode-server for this user
  vscode-server.enable = false;

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

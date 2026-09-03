{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

let
  claudeCommitMsg = pkgs.writeShellScript "claude-commit-msg" ''
    # Enforce only for commits made from inside Claude Code
    [ -n "''${CLAUDECODE:-}" ] || exit 0

    grep=${pkgs.gnugrep}/bin/grep
    sed=${pkgs.gnused}/bin/sed
    wc=${pkgs.coreutils}/bin/wc

    file="$1"
    subject=$($sed -n '1p' "$file")
    # Body = everything after line 1, minus comments, blanks, and trailers
    body=$($sed '1d' "$file" \
      | $grep -v '^#' \
      | $grep -Ev '^[A-Za-z-]+: ' \
      | $sed '/^[[:space:]]*$/d')
    body_lines=$(printf '%s' "$body" | $grep -c . || true)

    fail() { echo "commit-msg: $1" >&2; exit 1; }

    [ "''${#subject}" -le 72 ] || fail "subject is ''${#subject} chars, max 72"
    [ "$body_lines" -le 3 ]     || fail "body has $body_lines lines, max 3 one-line bullets"
    printf '%s\n' "$body" | $grep -q '^[^-]' \
      && fail "body lines must be bullets starting with '- '"
    printf '%s\n' "$body" | $grep -Eq '.{101,}' \
      && fail "body line over 100 chars; describe the change, not the process"
    exit 0
  '';
in

{
  imports = [ ../brendon/core.nix ];

  home.sessionVariables = {
    NVRMAP_CONFIG = "/home/brendon/.config/nvrmap/";
    NVRMAP_DB_PASSWORD = "$(${pkgs.coreutils}/bin/cat /home/brendon/.config/opnix/secrets/postgisPassword)";
  };

  home.packages = with pkgs; [
    geodiff
    trade-analysis
    db-nvrmap
    nodejs_24
    gsd-pi
  ];

  # enable core cli packages and settings
  core.enable = true;

  # enable extra dev packages and settings
  dev.enable = true;

  # CLI harnesses — installation is independent of GSD.
  programs.claude-code.enable = true;
  programs.git.hooks.commit-msg = claudeCommitMsg;

  # Personal Claude Code settings. These are the top override layer: they win
  # over GSD's installed settings.json and gsd-core's base defaults.
  programs.claude-code.settings = {
    includeCoAuthoredBy = false;
    model = "claude-opus-4-6[1m]";
    tui = "fullscreen";
    statusLine = {
      type = "command";
      command = "bash ${config.home.homeDirectory}/.claude/statusline-command.sh";
    };
    enabledPlugins = {
      "statusline@cc-marketplace" = true;
    };
  };

  programs.codex = {
    enable = true;
    # Optional: enable Model Context Protocol integration from programs.mcp
    enableMcpIntegration = true;
    settings = {
      model_provider = "openai";
      model = "gpt-5.6-sol";
      model_reasoning_effort = "low";
      approvals_reviewer = "auto_review";
      tui = {
        status-line = [
          "model-with-reasoning"
          "current-dir"
          "project-name"
          "git-branch"
          "approval-mode"
          "context-used"
        ];
      };
    };
  };

  # GSD files, per tool (each requires the matching programs.<tool>.enable above).
  gsd-core.claude-code.enable = true;
  gsd-core.codex.enable = true;
  gsd-browser.enable = true;

  # enable nixvim
  nixvim.enable = true;
  nixvim.wsl = true;

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
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}

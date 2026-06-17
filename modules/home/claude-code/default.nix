{ lib, pkgs, config, inputs, ... }:

let cfg = config.claude-code-gsd;
in {
  options = {
    claude-code.enable = lib.mkEnableOption "Claude Code CLI tool";
    claude-code-gsd.enable = lib.mkEnableOption "Claude Code GSD integration";

    claude-code-gsd.settingsOverride = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Personal Claude Code settings deep-merged over GSD's settings.json.
        These win on any key that also appears in GSD's settings (e.g. statusLine).
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.claude-code.enable {
      home.packages = [ pkgs.claude-code ];
    })

    (lib.mkIf config.claude-code-gsd.enable (
      let
        # GSD's files minus settings.json. settings.json is mutable runtime
        # state (Claude Code rewrites it), so it can't be a read-only HM
        # symlink; we manage it separately as a real file below.
        gsdFiles = pkgs.runCommand "gsd-core-claude-files" { } ''
          mkdir -p $out
          cp -a ${pkgs.gsd-core-claude}/. $out/
          chmod -R u+w $out
          rm -f $out/settings.json
        '';

        personal = pkgs.writeText "claude-personal-settings.json"
          (builtins.toJSON cfg.settingsOverride);

        # Deep-merge GSD's settings with the personal overrides; the personal
        # side wins on conflicting keys (jq's `*` recurses into objects).
        merged = pkgs.runCommand "claude-settings.json" { } ''
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
            ${pkgs.gsd-core-claude}/settings.json \
            ${personal} > $out
        '';
      in {
        home.file.".claude" = {
          source = gsdFiles;
          recursive = true;
        };

        # Install the merged settings.json as a real, writable file so Claude
        # Code can keep updating it at runtime. Re-established on every switch.
        home.activation.claudeSettings =
          config.lib.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p "$HOME/.claude"
            $DRY_RUN_CMD rm -f "$HOME/.claude/settings.json"
            $DRY_RUN_CMD install -m644 ${merged} "$HOME/.claude/settings.json"
          '';
      }
    ))

  ];
}

{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  cfg = config.claude-code-gsd;
  jsonFormat = pkgs.formats.json { };
in
{
  options = {
    claude-code-gsd.enable = lib.mkEnableOption "Claude Code GSD integration";
    gsd-browser.enable = lib.mkEnableOption "GSD Browser CLI tool";

    claude-code-gsd.settingsOverride = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Personal Claude Code settings deep-merged over GSD's settings.json.
        These win on any key that also appears in GSD's settings (e.g. statusLine).
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.gsd-browser.enable {
      home.packages = [ pkgs.gsd-browser ];
    })

    (lib.mkIf cfg.enable (
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

        personal = jsonFormat.generate "claude-personal-settings.json" cfg.settingsOverride;

        # Deep-merge GSD's settings with the personal overrides; the personal
        # side wins on conflicting keys (jq's `*` recurses into objects).
        # Done in a derivation rather than with lib.recursiveUpdate so that
        # reading GSD's settings.json doesn't force an import-from-derivation
        # at eval time.
        merged =
          pkgs.runCommand "claude-settings.json" { nativeBuildInputs = [ pkgs.jq ]; }
            ''
              jq -s '.[0] * .[1]' \
                ${pkgs.gsd-core-claude}/settings.json \
                ${personal} > $out
            '';
      in
      {
        # Upstream's programs.claude-code.settings writes settings.json as a
        # read-only store symlink, which Claude Code cannot write back to, so
        # we leave that option unset and own the file via the activation
        # script below. Everything else about the CLI comes from upstream.
        programs.claude-code.enable = true;

        home.file.".claude" = {
          source = gsdFiles;
          recursive = true;
        };

        # Install the merged settings.json as a real, writable file so Claude
        # Code can keep updating it at runtime. Re-established on every switch.
        # config.lib.dag, not lib.hm.dag: snowfall passes plain nixpkgs lib to
        # home modules, so lib.hm is not in scope here.
        home.activation.claudeSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/.claude"
          run rm -f "$HOME/.claude/settings.json"
          run install -m644 ${merged} "$HOME/.claude/settings.json"
        '';
      }
    ))

  ];
}

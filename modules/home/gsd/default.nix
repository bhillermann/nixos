{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.gsd;
  jsonFormat = pkgs.formats.json { };

  # Shared Claude Code base settings applied on every home that enables the
  # claude harness. Per-home deltas (gsd.claude.settingsOverride) deep-merge on
  # top of this; this in turn deep-merges over GSD's own settings.json. Kept as
  # an internal base (not an option) so machine-independent policy — permissions,
  # notifications — lives in exactly one place and can't be silently dropped by a
  # per-home override.
  claudeBaseSettings = {
    permissions = {
      allow = [
        "Bash(npx gsd-core *)"
        "Read(.planning/*)"
        "Edit(.planning/*)"
        "Read(STATE.md)"
        "Edit(STATE.md)"
      ];
      deny = [
        "Read(.env)"
        "Read(.env.*)"
        "Read(.secrets)"
      ];
    };
    defaultMode = "auto";
    preferredNotifChannel = "auto";
    inputNeededNotifEnabled = true;
    agentPushNotifEnabled = true;
    remoteControlAtStartup = true;
  };

  claudeBase = jsonFormat.generate "claude-base-settings.json" claudeBaseSettings;
  claudePersonal = jsonFormat.generate "claude-personal-settings.json" cfg.claude.settingsOverride;

  # Per-harness definitions. Each entry knows how to enable the harness binary,
  # where its config lives, and which file is the mutable runtime file that the
  # harness rewrites (so it can't be a read-only store symlink).
  harnessDefs = {
    claude = {
      package = pkgs.gsd-core-claude;
      configDir = ".claude";
      mutable = "settings.json";
      enableModule = {
        programs.claude-code.enable = true;
      };
      # Three-way deep-merge, later wins on conflicting keys (jq's `*` recurses
      # into objects): GSD's settings.json, then the shared base, then the
      # per-home deltas. Done in a derivation rather than with lib.recursiveUpdate
      # so reading GSD's settings.json doesn't force an import-from-derivation at
      # eval time.
      mutableSource = pkgs.runCommand "claude-settings.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        jq -s '.[0] * .[1] * .[2]' \
          ${pkgs.gsd-core-claude}/settings.json \
          ${claudeBase} \
          ${claudePersonal} > $out
      '';
    };
    codex = {
      package = pkgs.gsd-core-codex;
      configDir = ".codex";
      mutable = "config.toml";
      enableModule = {
        programs.codex.enable = true;
      };
      # No personal TOML override layer yet: install GSD's config.toml verbatim.
      # (Deep-merging TOML has no jq equivalent; add a merge step later if needed.)
      mutableSource = "${pkgs.gsd-core-codex}/config.toml";
    };
  };

  # GSD's files minus the mutable runtime file. That file is mutable runtime
  # state (the harness rewrites it), so it can't be a read-only HM symlink; we
  # manage it separately as a real writable file in the activation script below.
  gsdFilesFor =
    name: def:
    pkgs.runCommand "gsd-core-${name}-files" { } ''
      mkdir -p $out
      cp -a ${def.package}/. $out/
      chmod -R u+w $out
      rm -f $out/${def.mutable}
    '';

  # Guarded per-harness config. Iterate the full, static set of known harnesses
  # and gate each with mkIf, rather than deriving the list length from
  # cfg.harnesses — the latter makes the module structure depend on config and
  # triggers an infinite recursion in the fixpoint.
  mkHarness =
    name:
    let
      def = harnessDefs.${name};
    in
    lib.mkIf (builtins.elem name cfg.harnesses) (lib.mkMerge [
      # Enable the harness binary (provided by the llm-agents overlay). We leave
      # the module's own settings unset so it doesn't try to own the mutable
      # file — we manage that below as a writable file.
      def.enableModule

      {
        home.file.${def.configDir} = {
          source = gsdFilesFor name def;
          recursive = true;
        };

        # Install the merged/managed mutable file as a real, writable file so the
        # harness can keep updating it at runtime. Re-established on every switch.
        # config.lib.dag, not lib.hm.dag: snowfall passes plain nixpkgs lib to
        # home modules, so lib.hm is not in scope here.
        home.activation."gsd-${name}-mutable" = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/${def.configDir}"
          run rm -f "$HOME/${def.configDir}/${def.mutable}"
          run install -m644 ${def.mutableSource} "$HOME/${def.configDir}/${def.mutable}"
        '';
      }
    ]);
in
{
  options = {
    gsd.harnesses = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "claude"
        "codex"
      ]);
      default = [ ];
      example = [
        "claude"
        "codex"
      ];
      description = ''
        Coding harnesses to preinstall GSD for. Each entry enables that harness's
        binary and lays GSD's config into the harness config directory
        (~/.claude for claude, ~/.codex for codex), with the harness's mutable
        runtime file installed as a real writable file.
      '';
    };

    gsd-browser.enable = lib.mkEnableOption "GSD Browser CLI tool";

    gsd.claude.settingsOverride = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          model = "claude-opus-4-6[1m]";
          tui = "fullscreen";
          statusLine = {
            type = "command";
            command = "/bin/bash ''${config.home.homeDirectory}/.claude/statusline-command.sh";
          };
        }
      '';
      description = ''
        Per-home Claude Code deltas. Deep-merged on top of the shared base
        (claudeBaseSettings), which is itself deep-merged over GSD's own
        settings.json; keys set here win. Put only per-machine/personal tweaks
        here (model, statusLine, tui, …) — machine-independent policy like
        permissions lives in the module base. Only applies when "claude" is in
        gsd.harnesses.
      '';
    };
  };

  config = lib.mkMerge (
    [
      (lib.mkIf config.gsd-browser.enable {
        home.packages = [ pkgs.gsd-browser ];
      })
    ]
    ++ map mkHarness (builtins.attrNames harnessDefs)
  );
}

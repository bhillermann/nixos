{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.gsd-core;
  jsonFormat = pkgs.formats.json { };

  # gsd-core's own base defaults for Claude Code: machine-independent GSD policy
  # (the permission allow/deny list + notification defaults). This is the middle
  # layer of the settings merge — it sits above GSD's installed settings.json and
  # below the user's programs.claude-code.settings, which wins on any key.
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

  # The user's override layer comes straight from the standard Home Manager
  # options, so there's a single place to set settings per tool. gsd-core reads
  # them as data (IFD is disabled, so it can't read GSD's generated settings into
  # Nix; instead it merges everything in a derivation and owns the writable file).
  claudeUser = jsonFormat.generate "claude-user-settings.json" config.programs.claude-code.settings;
  codexUser = jsonFormat.generate "codex-user-settings.json" config.programs.codex.settings;

  # Per-tool definitions. Each knows: which CLI it needs (asserted, never enabled
  # here — installation is decoupled), where its config lives, the mutable runtime
  # file the tool rewrites, how to build that file (merged, writable), the exact
  # Home Manager home.file key that writes it (so we can suppress HM's read-only
  # write and own it ourselves), and the user's settings (override layer).
  harnessDefs = {
    "claude-code" = {
      cliEnabled = config.programs.claude-code.enable;
      cliOption = "programs.claude-code.enable";
      package = pkgs.gsd-core-claude;
      configDir = ".claude";
      mutable = "settings.json";
      userSettings = config.programs.claude-code.settings;
      # HM writes settings.json at this key (cfg.configDir defaults to the
      # absolute ~/.claude); match it exactly to disable it.
      suppressKey = "${config.programs.claude-code.configDir}/settings.json";
      # Three-way deep-merge, later wins (jq's `*` recurses into objects):
      # GSD's settings.json < gsd-core base < user's programs.claude-code.settings.
      mutableSource = pkgs.runCommand "claude-settings.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
        jq -s '.[0] * .[1] * .[2]' \
          ${pkgs.gsd-core-claude}/config/settings.json \
          ${claudeBase} \
          ${claudeUser} > $out
      '';
    };
    codex = {
      cliEnabled = config.programs.codex.enable;
      cliOption = "programs.codex.enable";
      package = pkgs.gsd-core-codex;
      configDir = ".codex";
      mutable = "config.toml";
      userSettings = config.programs.codex.settings;
      # HM writes ~/.codex/config.toml at this key (non-XDG, TOML format).
      suppressKey = ".codex/config.toml";
      # Deep-merge over GSD's installed config.toml via a TOML<->JSON round-trip:
      # toml -> json, jq-merge the user settings on top, json -> toml. yj emits
      # scalar keys before tables, so the result is valid TOML.
      mutableSource = pkgs.runCommand "codex-config.toml" { nativeBuildInputs = [ pkgs.yj pkgs.jq ]; } ''
        yj -tj < ${pkgs.gsd-core-codex}/config/config.toml > gsd.json
        jq -s '.[0] * .[1]' gsd.json ${codexUser} > merged.json
        yj -jt < merged.json > $out
      '';
      # Codex discovers user skills from ~/.agents/skills (per OpenAI's skill
      # docs), and GSD installs its slash-command skills there — not into the
      # config dir. Lay the whole skills root down as a single directory symlink:
      # Codex does not follow symlinked SKILL.md files (openai/codex#10470), but
      # a symlinked containing directory with real files underneath works.
      agentsSkills = "${pkgs.gsd-core-codex}/agents-skills";
    };
  };

  # GSD's files minus the mutable runtime file. That file is mutable runtime
  # state (the tool rewrites it), so it can't be a read-only HM symlink; we
  # manage it separately as a real writable file in the activation script below.
  gsdFilesFor =
    name: def:
    pkgs.runCommand "gsd-core-${name}-files" { } ''
      mkdir -p $out
      cp -a ${def.package}/config/. $out/
      chmod -R u+w $out
      rm -f $out/${def.mutable}
    '';

  # Guarded per-tool config. Iterate the full, static set of known tools and gate
  # each with mkIf, rather than deriving the set from an enable list — the latter
  # makes the module structure depend on config and triggers an infinite recursion
  # in the fixpoint.
  mkHarness =
    name:
    let
      def = harnessDefs.${name};
    in
    lib.mkIf cfg.${name}.enable (lib.mkMerge [
      {
        # Installation is decoupled: gsd-core lays down GSD's files but never
        # enables the CLI. Fail loudly if the matching program isn't enabled.
        assertions = [
          {
            assertion = def.cliEnabled;
            message = ''
              gsd-core.${name}.enable requires ${def.cliOption} = true.
              gsd-core installs GSD's files for a tool but not the tool itself —
              enable the CLI separately.
            '';
          }
        ];

        home.file =
          {
            ${def.configDir} = {
              source = gsdFilesFor name def;
              recursive = true;
            };
          }
          # Codex-style skills root at ~/.agents/skills: single directory symlink
          # (recursive = false) so SKILL.md files stay real, not symlinked.
          // lib.optionalAttrs (def ? agentsSkills) {
            ".agents/skills".source = def.agentsSkills;
          }
          # When the user sets programs.<tool>.settings, HM would write the
          # mutable file itself as a read-only store symlink, clobbering the
          # writable file we install below. Disable HM's write on that exact key;
          # we fold those settings into our merged file instead. Guarded so we
          # never create a source-less home.file entry when HM wrote nothing.
          // lib.optionalAttrs (def.userSettings != { }) {
            ${def.suppressKey}.enable = lib.mkForce false;
          };

        # Install the merged mutable file as a real, writable file so the tool can
        # keep updating it at runtime. Re-established on every switch.
        # config.lib.dag, not lib.hm.dag: snowfall passes plain nixpkgs lib to
        # home modules, so lib.hm is not in scope here.
        home.activation."gsd-core-${name}-mutable" = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/${def.configDir}"
          run rm -f "$HOME/${def.configDir}/${def.mutable}"
          run install -m644 ${def.mutableSource} "$HOME/${def.configDir}/${def.mutable}"
        '';
      }
    ]);
in
{
  options = {
    gsd-core.claude-code.enable = lib.mkEnableOption ''
      installing GSD's files for Claude Code (agents, hooks, skills and a merged,
      writable settings.json). Requires programs.claude-code.enable = true; the
      CLI itself is installed separately'';

    gsd-core.codex.enable = lib.mkEnableOption ''
      installing GSD's files for Codex (agents, hooks, ~/.agents/skills and a
      merged, writable config.toml). Requires programs.codex.enable = true; the
      CLI itself is installed separately'';

    gsd-browser.enable = lib.mkEnableOption "GSD Browser CLI tool";
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

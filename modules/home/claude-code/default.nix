{ lib, pkgs, config, inputs, ... }:

let
  gsd = pkgs.fetchFromGitHub {
    owner = "gsd-build";
    repo = "get-shit-done";
    rev = "v1.18.0";
    hash = "sha256-PbvmJkFv1NHd7pc+N4lVh/8ZiQHuPpUpCZLQIX3VZxs=";
  };

in {
  options = {
    claude-code = {
      enable = lib.mkOption {
        description = "Enable Claude Code cli tool.";
        type = lib.types.bool;
        default = false;
      };
    };

    claude-code-gsd = {
      enable = lib.mkOption {
        description = "Enable Claude Code GSD integration.";
        type = lib.types.bool;
        default = false;
      };
    };

  };

  config = lib.mkMerge [
    (lib.mkIf config.claude-code-gsd.enable {
      home.activation.installGSD =
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.claude/commands/gsd \
                   $HOME/.claude/agents \
                   $HOME/.claude/hooks \
                   $HOME/.claude/get-shit-done

          # Slash commands (the /gsd:* entrypoints)
          cp -r ${gsd}/commands/gsd/* $HOME/.claude/commands/gsd/

          # Agents
          cp -r ${gsd}/agents/* $HOME/.claude/agents/

          # Hooks
          [ -d ${gsd}/hooks ] && cp -r ${gsd}/hooks/* $HOME/.claude/hooks/ || true

          # Core GSD runtime (workflows, templates, references)
          cp -r ${gsd}/get-shit-done/* $HOME/.claude/get-shit-done/
        '';
    })
  ];
}

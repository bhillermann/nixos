{ inputs, ... }:

# Override the top-level attrs so Home Manager's programs.claude-code /
# programs.codex modules pick these up as their default package. numtide's
# own `shared-nixpkgs` overlay only nests packages under `pkgs.llm-agents.*`,
# which the HM modules wouldn't see.
final: prev:
let
  llm = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
in
{
  claude-code = llm.claude-code;
  codex = llm.codex;
}

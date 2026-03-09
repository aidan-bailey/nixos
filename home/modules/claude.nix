{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

let
  claude-squad = pkgs.buildGoModule rec {
    pname = "claude-squad";
    version = "1.0.16";
    src = pkgs.fetchFromGitHub {
      owner = "smtg-ai";
      repo = "claude-squad";
      rev = "v${version}";
      hash = "sha256-ecR+CqCO6uoWd6yVN3QpZAnA/xWZIOAHvwjbJgAQwNo=";
    };
    vendorHash = "sha256-Rc0pIwnA0k99IKTvYkHV54RxtY87zY1TmmmMl+hYk6Q=";
    env.CGO_ENABLED = 0;
    doCheck = false;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram $out/bin/claude-squad --prefix PATH : ${lib.makeBinPath [ pkgs.tmux pkgs.gh pkgs.git ]}
    '';
  };

  tail-claude = pkgs.buildGoModule rec {
    pname = "tail-claude";
    version = "0.3.5";
    src = pkgs.fetchFromGitHub {
      owner = "kylesnowschwartz";
      repo = "tail-claude";
      rev = "v${version}";
      hash = "sha256-bKmcdjO1vWumgW5zqJf3wUPI3XPgqSof3PtI98NY/Oc=";
    };
    vendorHash = "sha256-BE+tZvkjR36cN0SGjUZNylU2J58FVUZfpFw3+2ObfNc=";
    env.CGO_ENABLED = 0;
  };
in
{
  home.packages = [
    inputs.claude-code-nix.packages.${system}.default
    pkgs.jq
    pkgs.bun
    claude-squad
    tail-claude
    (pkgs.mcp-nixos.overridePythonAttrs { doCheck = false; })
  ];

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
  ];

  home.file.".claude/hooks/notify.sh" = {
    source = ../../config/claude/hooks/notify.sh;
    executable = true;
  };

  sops.secrets.claude_code_oauth_token = { };
  programs.zsh.profileExtra = ''
    export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${config.sops.secrets.claude_code_oauth_token.path})"
  '';
}

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
      mv $out/bin/claude-squad $out/bin/cs
      wrapProgram $out/bin/cs --prefix PATH : ${lib.makeBinPath [ pkgs.tmux pkgs.gh pkgs.git ]}
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

  devlibs = with pkgs; [
    # Essentials
    ffmpeg
    libtool
    cmake
    clang
    llvm
    curl
    gh
    pkg-config
    gnumake
    mold

    # Shell
    shfmt
    shellcheck
    nodePackages.bash-language-server
    nodePackages.pnpm

    # Markdown
    uv
    pandoc
    marksman

    # Nix
    nixd
    nixfmt

    # Antigravity
    inputs.antigravity-nix.packages.${system}.default
    (inputs.harbour.lib.mkHarbour {
      inherit pkgs;
      buildOpts = {
        enableFreeImage = false;
        enableCurl = true;
        enableOpenSSL = true;
      };
    })
    # JS
    nodejs_22

    # DB
    postgresql
    dbeaver-bin
    # Emulation
    qemu
    libvirt
    swtpm
    guestfs-tools
    libosinfo
    virtiofsd
    # Python
    python3
    pyright
    pyenv
    semgrep
    pipenv
    # XML
    libxslt
    # Rust
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [ "clippy" "rustfmt" "rust-analyzer" "rust-src" ];
    })
    cargo-audit
    cargo-machete
    sccache # Rust compilation caching
    lldb
    autoconf
    automake

    # Claude Code ecosystem
    tmux # claude-squad session management
    jq # notification hook JSON parsing
    bun # ralph-tui runtime
    claude-squad
    tail-claude
    (mcp-nixos.overridePythonAttrs { doCheck = false; }) # NixOS MCP server (tests broken in nixpkgs)
  ];
in
{
  home.packages = [
    inputs.claude-code-nix.packages.${system}.default
  ]
  ++ devlibs;

  # Session variables
  home.sessionVariables = {
    LD = "mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
  ];

  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    baseIndex = 1;
  };

  home.file.".claude/hooks/notify.sh" = {
    source = ../../config/claude/hooks/notify.sh;
    executable = true;
  };

  # Secrets
  sops.secrets.claude_code_oauth_token = { };
  programs.zsh.profileExtra = ''
    export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${config.sops.secrets.claude_code_oauth_token.path})"
  '';
}

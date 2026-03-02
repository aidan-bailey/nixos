{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

let
  tools = with pkgs; [
    teamviewer
    clockify
    remmina
    slack
    vscode
    # zed-editor-fhs # Don't use this if using programs.zed-editor
    code-cursor
    opencode
    claude-code
    google-cloud-sdk
    gemini-cli
  ];

  # mkZedLsp: Build a Zed LSP config pointing at a Nix-provided binary.
  # Fixes "Invalid gzip header" errors by bypassing Zed's auto-download.
  mkZedLsp = { pkg, bin ? pkg.pname or (builtins.parseDrvName pkg.name).name, args ? [] }: {
    binary = { path = "${pkg}/bin/${bin}"; } // lib.optionalAttrs (args != []) { arguments = args; };
  };

  devlibs = with pkgs; [
    # Essentials
    ffmpeg
    direnv
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
    rustup # For the toolchain (cargo, rustc)
    sccache # Rust compilation caching
    lldb
    autoconf
    automake
  ];
in
{
  # 1. Install all tools and libraries
  home.packages = tools ++ devlibs;

  # 2. Configure Zed
  programs.zed-editor = {
    enable = true;

    # Note: On NixOS, auto-installing extensions can sometimes fail
    # (the "gzip" error in your logs). If this persists, comment this list out
    # and install them manually inside Zed once, then let Nix manage the config.
    extensions = [
      "rust"
      "python"
      "toml"
      "direnv"
      "make"
      "nix"
    ];

    userSettings = {
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 14;
      theme = "One Dark";

      # Environment setup
      load_direnv = "direct"; # Uses the direnv extension

      # Language specific settings
      languages = {
        Python = {
          language_servers = [
            "pyright"
            "ruff"
          ];
          format_on_save = "on";
          formatter = {
            external = {
              command = "${pkgs.ruff}/bin/ruff";
              arguments = [
                "format"
                "--stdin-filename"
                "{buffer_path}"
              ];
            };
          };
        };
        Rust = {
          language_servers = [ "rust-analyzer" ];
          format_on_save = "on";
        };
        Nix = {
          language_servers = [ "nixd" ];
          format_on_save = "on";
        };
      };

      userKeymaps = [
        {
          context = "Editor && menu_open";
          bindings = {
            "tab" = "menu::SelectNext";
            "shift-tab" = "menu::SelectPrev";
          };
        }
      ];

      # Nix-provided LSP paths — bypasses Zed's auto-download
      lsp = {
        rust-analyzer = mkZedLsp { pkg = pkgs.rust-analyzer; };
        pyright = mkZedLsp { pkg = pkgs.pyright; bin = "pyright-langserver"; args = [ "--stdio" ]; };
        ruff = mkZedLsp { pkg = pkgs.ruff; args = [ "server" ]; };
        nixd = mkZedLsp { pkg = pkgs.nixd; };
      };
    };
  };

  # Session variables
  home.sessionVariables = {
    LD = "mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true";
  };

  # Secrets
  sops.secrets.claude_code_oauth_token = {};
  home.sessionVariablesExtra = ''
    export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${config.sops.secrets.claude_code_oauth_token.path})"
  '';
}

{ config, pkgs, inputs, system, ... }:

let
  tools = with pkgs; [
    teamviewer
    clockify
    remmina
    slack
    vscode
    #zed-editor-fhs
    code-cursor
    opencode
  ];

  devlibs = with pkgs; [
    # Essentials
    ffmpeg
    direnv
    libtool
    cmake
    clang
    llvm
    curl
    pkg-config
    gnumake
    # gcc removed - conflicts with clang (both provide bin/ld)
    # stdenv removed - not a user package, it's the build environment
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
    nixfmt-rfc-style
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
    python3 # Full
    (lib.lowPrio python314FreeThreading)
    pyright
    pyenv
    semgrep
    pipenv
    # XML
    libxslt
    # Rust
    rustup
    lldb
    autoconf
    automake
  ];
in
{
  # Development tools and libraries
  home.packages = tools ++ devlibs;

  programs.zed-editor = {
      enable = true;
      # These extensions will be automatically installed
      extensions = [ "opencode" "rust" "python" "ruff" "toml" "direnv" ];

      userSettings = {
        vim_mode = true;
        ui_font_size = 16;
        buffer_font_size = 14;
        theme = "One Dark"; # Or your preferred theme

        # Language specific settings
        languages = {
          Python = {
            language_servers = [ "pyright" "ruff" ];
            format_on_save = "on";
          };
          Rust = {
            language_servers = [ "rust-analyzer" ];
            format_on_save = "on";
          };
        };

        # Force Zed to use Nix-provided binaries
        lsp = {
          rust-analyzer = {
            binary = { path = "${pkgs.rust-analyzer}/bin/rust-analyzer"; };
          };
          pyright = {
            binary = { path = "${pkgs.pyright}/bin/pyright-langserver"; arguments = [ "--stdio" ]; };
          };

        };
        
        load_direnv = "shell_hook";


      };
  };
  # Session variables
  home.sessionVariables = {
    LD = "mold";
  };
}


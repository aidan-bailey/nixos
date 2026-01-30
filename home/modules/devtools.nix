{ config, pkgs, inputs, system, ... }:

let
  tools = with pkgs; [
    teamviewer
    clockify
    remmina
    slack
    vscode
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

  # Session variables
  home.sessionVariables = {
    LD = "mold";
  };
}


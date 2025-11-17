{ config, pkgs, ... }:

let
  tools = with pkgs; [
    teamviewer
    clockify
    remmina
    slack
    vscode
    code-cursor
  ];

  devlibs = with pkgs; [
    # Essentials
    ffmpeg
    direnv
    libtool
    cmake
    clang
    llvm
    gnumake
    # gcc removed - conflicts with clang (both provide bin/ld)
    # stdenv removed - not a user package, it's the build environment
    mold
    # Shell
    shfmt
    shellcheck
    nodePackages.bash-language-server
    # Markdown
    uv
    pandoc
    marksman
    # Nix
    nixd
    nixfmt-rfc-style
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
    pyright
    pyenv
    semgrep
    pipenv
    # XML
    libxslt
    # Rust
    rustup
    lldb
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


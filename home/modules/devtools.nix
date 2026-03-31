{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

let
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
      extensions = [
        "clippy"
        "rustfmt"
        "rust-analyzer"
        "rust-src"
      ];
    })
    cargo-audit
    cargo-machete
    sccache # Rust compilation caching
    lldb
    autoconf
    automake

    tmux
  ];
in
{
  home.packages = devlibs;

  # Session variables
  home.sessionVariables = {
    LD = "mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    baseIndex = 1;
  };
}

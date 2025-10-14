{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    # Essentials
    direnv
    libtool
    cmake
    gnumake
    gcc
    stdenv
    # Shell
    shfmt
    shellcheck
    nodePackages.bash-language-server
    # Markdown
    uv
    pandoc
    marksman
    # Emacs
    ripgrep
    fd
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

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      glib
      libGL
      libxkbcommon
      fontconfig
      xorg.libX11 # keep for some legacy apps (via XWayland)
      freetype
      dbus
      libkrb5
      krb5
      libpulseaudio
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm
      xorg.xcbutilcursor # this is the “xcb-cursor0 / libxcb-cursor0” that Qt demands
      # NEW: PipeWire for QtMultimedia (6.9 tries pipewire-0.3)
      pipewire
      # Wayland client libs (helpful even if you use xcb via XWayland sometimes)
      wayland
      wayland-protocols
      # Optional but sometimes needed for decorations on Wayland:
      libdecor
    ];
  };

}

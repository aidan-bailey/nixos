{
  config,
  lib,
  pkgs,
  ...
}:

let
  ldlibs = with pkgs; [
    brotli
    stdenv.cc.cc
    zlib
    zstd
    glib
    gcc
    curl.dev
    gtk2
    cairo
    pkg-config
    openssl
    libGL
    libxkbcommon
    fontconfig
    libx11 # keep for some legacy apps (via XWayland)
    freetype
    dbus
    libkrb5
    krb5
    libpulseaudio
    libxcb
    libxcb-image
    libxcb-keysyms
    libxcb-wm
    libxcb-cursor # this is the "xcb-cursor0 / libxcb-cursor0" that Qt demands
    # NEW: PipeWire for QtMultimedia (6.9 tries pipewire-0.3)
    pipewire
    # Wayland client libs (helpful even if you use xcb via XWayland sometimes)
    wayland
    wayland-protocols
    # Optional but sometimes needed for decorations on Wayland:
    libdecor
  ];
in
{
  # nix-ld is a system-level program for loading dynamic libraries
  programs.nix-ld = {
    enable = true;
    libraries = ldlibs;
  };
}


{
  config,
  lib,
  pkgs,
  ...
}:

let
  ldlibs = with pkgs; [
    # Core C/C++ runtime and compression — needed by most dynamically-linked binaries
    stdenv.cc.cc # libstdc++
    gcc          # libgcc_s
    zlib         # general-purpose compression (curl, git, Python, etc.)
    zstd         # Zstandard compression (systemd, btrfs tools)
    brotli       # HTTP content encoding (curl, browsers)

    # Networking and security
    curl.dev     # libcurl headers (code-cursor, various dev tools)
    openssl      # TLS/SSL (curl, Python requests, Node.js)
    libkrb5      # Kerberos auth (remmina, code-cursor)
    krb5         # Kerberos client libraries

    # Graphics and rendering
    libGL        # OpenGL (Steam, gaming, GPU-accelerated apps)
    cairo        # 2D graphics (GTK apps, Zed, Firefox)
    freetype     # Font rendering (most GUI apps)
    fontconfig   # Font discovery (most GUI apps)

    # GUI toolkit dependencies
    gtk2         # GTK2 apps (some legacy tools, Steam)
    glib         # GLib (GTK apps, D-Bus clients)
    dbus         # D-Bus IPC (desktop apps, system services)
    pkg-config   # build-time dependency resolution

    # X11/XCB — needed for XWayland compatibility
    libx11       # legacy X11 apps via XWayland
    libxkbcommon # keyboard handling (Sway, Wayland clients, Zed)
    libxcb       # X protocol C bindings (Qt, Electron apps)
    libxcb-image   # XCB image extension (Qt)
    libxcb-keysyms # XCB key symbols (Qt)
    libxcb-wm      # XCB window management (Qt)
    libxcb-cursor  # xcb-cursor0 — required by Qt6

    # Audio
    libpulseaudio # PulseAudio client (Electron apps, Steam, Discord)
    pipewire      # PipeWire client — QtMultimedia 6.9+ requires pipewire-0.3

    # Wayland
    wayland          # Wayland client protocol (native Wayland apps)
    wayland-protocols # Wayland protocol extensions
    libdecor         # client-side window decorations on Wayland
  ];
in
{
  # nix-ld is a system-level program for loading dynamic libraries
  programs.nix-ld = {
    enable = true;
    libraries = ldlibs;
  };
}


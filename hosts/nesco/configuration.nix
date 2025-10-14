# Aidan's NixOS config — Wayland/Sway

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let

  basePackages = with pkgs; [
    wget
    vim
    neovim
    curl
    htop
    git
    unzip
    xfce.thunar
    smartmontools
    zoom-us
    gparted
    nvme-cli
    ddrescue
    geeqie
    zstd
    nix-index
    wdisplays
    maim
    btop
    glmark2
    radeontop
    libva
    glxinfo
    lact
  ];

  guiPackages = with pkgs; [
    # Wayland-friendly replacements
    wofi # replaces rofi
    swaybg # replaces feh for wallpapers
    lxappearance
    pavucontrol
    networkmanagerapplet
    vlc
    wlr-randr # quick output changes
    # arandr removed (XRandR/X11-only)
  ];

  devPackages = with pkgs; [
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
    ruff
    # XML
    libxslt
    # Rust
    #cargo
    rustup
    lldb
    #rust-analyzer
    #rustc
    #cargo
    #rustfmt
    #clippy
    # Nix
    nixfmt-rfc-style
  ];

  apps = with pkgs; [
    brave
    vivaldi
    thunderbird
    protonmail-bridge
    discord
    firefox
    spotify
    steam
    gamescope
    cockatrice
  ];

  tools = with pkgs; [
    mupdf
    qbittorrent-enhanced
    slack
    vscode
    emacs-git
    remmina
    clockify
    pomodoro-gtk
    protonvpn-gui
    bitwarden-desktop
    bitwarden-menu
    code-cursor
    element-desktop
    teamviewer
  ];

  scripts = [
    (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
  ];

in
{

  ##############
  # SYS CONFIG #
  ##############

  system.stateVersion = "25.05";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
    ];
  };
  environment.pathsToLink = [ "/libexec" ];
  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.enableRedistributableFirmware = true;

  imports = [
    ./hardware-configuration.nix
    ../../modules/sway.nix
    ../../modules/audio.nix
    ../../modules/terminal.nix
    ../../modules/bluetooth.nix
    ../../modules/networking.nix
    ../../modules/virtualisation.nix
    ../../modules/zenbook_s16/power.nix
    ../../modules/amd/cpu.nix
    ../../modules/amd/graphics.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # In your configuration.nix
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };

  #########
  # USERS #
  #########

  services.getty = {
    autologinUser = "aidanb";
    autologinOnce = true;
  };

  # Locale + TZ.
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";
  environment.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
  };

  #########
  # AUDIO #
  #########

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.noto
  ];

  # Services
  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

  ##################
  # VIRTUALISATION #
  ##################

  ############
  # PACKAGES #
  ############

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (
      builtins.fetchTarball {
        # pin emacs overlay as you had it
        url = "https://github.com/nix-community/emacs-overlay/archive/29430cce2da82c0f658cd3310191434bf709f245.tar.gz";
        sha256 = "02l1f9d3qr634ja32psj63938wh0lp87fpnkgcmk7a82vpbk3qjh";
      }
    ))
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

  #########
  # STEAM #
  #########

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
      pkgs.vkd3d-proton
    ];
  };

  environment.systemPackages = basePackages ++ guiPackages ++ devPackages ++ scripts;

  # User
  users.users.aidanb = {
    isNormalUser = true;
    description = "Aidan Bailey";
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "wheel"
      # "input" "video" # add if some Wayland apps complain about permissions
    ];
    shell = pkgs.zsh;
    packages = apps ++ tools;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOX/kOPgPyOn9iJ5YhPK9+F2Ek9YaYqvrA6k2Ki+ALQ1 aidanb@nesco"
    ];
  };

}

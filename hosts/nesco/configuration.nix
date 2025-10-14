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
  ];

  apps = with pkgs; [
    brave
    vivaldi
    thunderbird
    protonmail-bridge
    discord
    firefox
    spotify
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
    ../../modules/gaming.nix
    ../../modules/devtools.nix
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

  ############
  # PACKAGES #
  ############

  environment.systemPackages = basePackages ++ guiPackages ++ scripts;

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

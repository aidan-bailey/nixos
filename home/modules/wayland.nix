{ config, pkgs, ... }:

{
  # Wayland user-specific configuration
  # System-level Wayland config is in modules/sway.nix

  # Wayland user packages
  home.packages = with pkgs; [
    waybar
    swaybg
    swayidle
    swaylock
    wofi
    kanshi
    wlr-randr
    slurp
    wl-clipboard
    mako
    libnotify
    xdg-user-dirs
    xdg-desktop-portal-wlr
    networkmanagerapplet
    pavucontrol
    lxappearance
    wf-recorder
    grim
    gnome-keyring
    wdisplays
    brightnessctl
    gnome-themes-extra
    adwaita-icon-theme
    adwaita-qt
    wayvnc
  ];

  # Wayland session variables
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    CLUTTER_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
  };

  # Waybar configuration
  programs.waybar.enable = true;

  # Sway configuration
  xdg.configFile."sway/config".source = ../../config/sway/config;
  xdg.configFile."sway/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

  # Waybar configuration
  xdg.configFile."waybar/config".source = ../../config/waybar/config;
  xdg.configFile."waybar/style.css".source = ../../config/waybar/style.css;

  # Kanshi display profile daemon (user service)
  systemd.user.services.kanshi = {
    Unit = {
      Description = "kanshi daemon";
    };
    Service = {
      Type = "simple";
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "DISPLAY=:0"
      ];
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c ${config.home.homeDirectory}/.config/kanshi/config'';
    };
  };

  # Configure XDG user directories
  # This sets up the standard directories (Pictures, Documents, etc.)
  # Customized to match your Media directory structure from init.sh
  # Note: XDG only supports standard directory types (PICTURES, MUSIC, etc.)
  # Custom directories like "screenshots" aren't part of the XDG spec
  xdg.userDirs = {
    enable = true;
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Media/Music";
    pictures = "${config.home.homeDirectory}/Media/Pictures";
    videos = "${config.home.homeDirectory}/Media/Videos";
    desktop = "${config.home.homeDirectory}/Desktop";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
  };

  # Custom environment variable for screenshots directory
  home.sessionVariables.SCREENSHOTS_DIR = "${config.home.homeDirectory}/Media/Pictures/Screenshots";

}


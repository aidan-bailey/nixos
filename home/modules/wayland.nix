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
    cliphist
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
    sway-audio-idle-inhibit
    polkit_gnome
  ];

  # HiDPI cursor (Adwaita at 1.5x = 36)
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 36;
    gtk.enable = true;
    x11.enable = true;
  };

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
    XCURSOR_SIZE = "36";
  };

  # Night light (color temperature adjustment)
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = -33.9;
    longitude = 18.4;
    temperature = {
      day = 6500;
      night = 3500;
    };
    tray = true;
  };

  # Waybar configuration — launched by Sway's bar block (swaybar_command),
  # so disable the systemd service to avoid a duplicate instance.
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  # Sway configuration (per-host config sourced from home/hosts/<host>.nix)
  xdg.configFile."sway/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

  # Waybar configuration
  xdg.configFile."waybar/config".source = ../../config/waybar/config;
  xdg.configFile."waybar/style.css".source = ../../config/waybar/style.css;

  # Polkit authentication agent for GUI privilege escalation
  systemd.user.services.polkit-gnome = {
    Unit = {
      Description = "PolicyKit Authentication Agent";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
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


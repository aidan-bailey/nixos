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
  # Manage sway config file from configs/config
  xdg.configFile."sway/config".source = ../../configs/sway;

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

}


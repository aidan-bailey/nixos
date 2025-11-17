{ config, lib, pkgs, ... }:

let
  firefoxWrapped = (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {
    pipewireSupport = true;
  }) {});
in
{
  # User applications
  home.packages = with pkgs; [
    thunderbird
    protonmail-bridge
    discord
    firefoxWrapped
    spotify
    vlc
    mupdf
    qbittorrent-enhanced
    pomodoro-gtk
    protonvpn-gui
    bitwarden-desktop
    bitwarden-menu
    element-desktop
    zoom-us
    xfce.thunar
    protonmail-bridge
    protonmail-bridge-gui
    gimp
  ];

  # Session variables
  home.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
  };

  # Default applications for MIME types
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };

}


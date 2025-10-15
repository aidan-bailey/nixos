{
  config,
  lib,
  pkgs,
  ...
}:

let
  apps = with pkgs; [
    thunderbird
    protonmail-bridge
    discord
    firefox
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
in
{

  environment.systemPackages = apps;

  environment.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
  };

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

}

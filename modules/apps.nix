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
  ];
in
{

  environment.systemPackages = apps;

}

# Aidan's NixOS config — Wayland/Sway

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let

in
{

  imports = [
    ./hardware-configuration.nix
    ../../modules/kernel/cachyos.nix
    ../../modules/devices/zenbook_s16.nix
    ../../modules/base.nix
    ../../modules/sway.nix
    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/terminal.nix
    ../../modules/bluetooth.nix
    ../../modules/networking.nix
    ../../modules/user.nix
    ../../modules/gaming.nix
    ../../modules/devtools.nix
    ../../modules/virtualisation.nix
    ../../modules/power.nix
  ];



}

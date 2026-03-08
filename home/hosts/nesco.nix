{ lib, ... }:
{
  imports = [ ../profiles/desktop.nix ];
  xdg.configFile."sway/config".source = ../../config/sway/nesco/config;
  xdg.configFile."waybar/config".source = lib.mkForce ../../config/waybar/nesco/config;
}

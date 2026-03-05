{ lib, ... }: {
  xdg.configFile."sway/config".source = ../../config/sway/fresco/config;
  xdg.configFile."waybar/config".source = lib.mkForce ../../config/waybar/fresco/config;
}

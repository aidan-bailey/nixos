{ config, pkgs, ... }:

{
  imports = [
    ../modules/apps.nix
    ../modules/gaming.nix
  ];

  # Openbox configuration
  xdg.configFile."openbox/rc.xml".source = ../../config/openbox/rc.xml;
  xdg.configFile."openbox/menu.xml".source = ../../config/openbox/menu.xml;
  xdg.configFile."openbox/autostart" = {
    source = ../../config/openbox/autostart;
    executable = true;
  };

  # Reuse the shared wallpaper
  xdg.configFile."openbox/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

  # HTPC packages
  home.packages = with pkgs; [
    tint2
    feh
    rofi
    xclip
    xdotool
    picom
    gruvbox-dark-gtk
    gruvbox-dark-icons-gtk
  ];

  # Gruvbox theming (consistent with nesco/fresco)
  home.pointerCursor = {
    name = "Capitaine Cursors (Gruvbox)";
    package = pkgs.capitaine-cursors-themed;
    size = 36;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    GTK_THEME = "Gruvbox-Dark";
  };
}

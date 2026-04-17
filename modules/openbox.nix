{
  config,
  lib,
  pkgs,
  ...
}:

{
  # X11 server with Openbox
  services.xserver = {
    enable = true;
    windowManager.openbox.enable = true;
    xkb = {
      layout = "za";
      variant = "";
      options = "caps:swapescape";
    };
  };
  console.useXkbConfig = true;

  # Auto-login to Openbox session via LightDM
  services.displayManager.autoLogin = {
    enable = true;
    user = "aidanb";
  };

  # Desktop plumbing
  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.noto
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Font rendering — adapts to display panel technology
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel =
      if config.custom.display.type == "lcd" then
        {
          rgba = "rgb";
          lcdfilter = "default";
        }
      else
        {
          rgba = "none";
          lcdfilter = "none";
        };
  };

  environment.systemPackages = with pkgs; [
    libsecret
  ];
}

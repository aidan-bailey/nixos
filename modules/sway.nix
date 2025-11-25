{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  security.rtkit.enable = true;

  services.xserver.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  programs.sway = {
    enable = true;
    package = pkgs.sway_git;
    wrapperFeatures.gtk = true;
    xwayland.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;

  services.picom.enable = lib.mkForce false;

  # Fonts (system-level)
  fonts.packages = with pkgs; [
    nerd-fonts.noto
    libsecret
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  # Keyboard layout (exports XKB_* for Wayland too)
  services.xserver.xkb = {
    layout = "za";
    variant = "";
    options = "caps:swapescape";
  };
  console.useXkbConfig = true;

  services.xrdp.enable = lib.mkForce false;

}

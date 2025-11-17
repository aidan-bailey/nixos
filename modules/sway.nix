{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Force all packages to use wayland_git instead of stable wayland
  nixpkgs.overlays = [
    (final: prev: {
      #wayland = prev.wayland_git;
      #wlroots = prev.wlroots_git;
      #sdl3 = prev.sdl3.overrideAttrs (_: { doCheck = false; });
      xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr_git;
    })
  ];

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  security.rtkit.enable = true;

  services.xserver.enable = false;

  #chaotic.hdr.enable = true;

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

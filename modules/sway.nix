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

  services.xserver.enable = false;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    xwayland.enable = true;
    extraSessionCommands = "
    	export XDG_CURRENT_DESKTOP=sway
	    export XDG_SESSION_DESKTOP=sway
    ";

    extraPackages = with pkgs; [
      waybar
      swaybg
      swayidle
      swaylock
      wofi
      kanshi
      wlr-randr
      grim
      slurp
      wl-clipboard
      mako
      xdg-desktop-portal-wlr
      wlr-randr
      networkmanagerapplet
      pavucontrol
      lxappearance
    ];

  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.waybar.enable = true;

  environment.systemPackages = with pkgs; [
    wdisplays
    brightnessctl
    kanshi # display profiles
  ];

  services.picom.enable = lib.mkForce false;

  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    #environment = {
    #  WAYLAND_DISPLAY="wayland-1";
    #  DISPLAY = ":0";
    #};
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /home/aidanb/.config/kanshi/config'';
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
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

  # Example to try:
  # services.wayvnc = {
  #   enable = true;
  #   users = [ "aidanb" ];
  #   openFirewall = true;
  #   settings = { address = "0.0.0.0"; };
  # };

}

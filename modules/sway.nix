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
    extraSessionCommands = "
    	export XDG_CURRENT_DESKTOP=sway
	export XDG_SESSION_DESKTOP=sway
    	export GTK_THEME=Adwaita:dark
    	export QT_QPA_PLATFORMTHEME=gtk3
    	export SDL_VIDEODRIVER=wayland
    	export QT_QPA_PLATFORM=wayland
    	export XDG_SESSION_TYPE=wayland
    	export CLUTTER_BACKEND=wayland
    	export NIXOS_OZONE_WL=1
    	export MOZ_ENABLE_WAYLAND=1
    ";

    extraPackages = with pkgs; [
      waybar
      swaybg
      swayidle
      swaylock
      wofi
      kanshi
      wlr-randr
      slurp
      wl-clipboard
      mako
      xdg-desktop-portal-wlr
      networkmanagerapplet
      pavucontrol
      lxappearance
    ];

  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.noto
  ];

  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    CLUTTER_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.waybar.enable = true;

  environment.systemPackages = with pkgs; [
    wf-recorder
    grim
    gnome-keyring
    wdisplays
    brightnessctl
    kanshi # display profiles
    wdisplays
    gnome-themes-extra
    adwaita-icon-theme
    adwaita-qt
  ];

  services.gnome.gnome-keyring.enable = true;

  services.picom.enable = lib.mkForce false;

  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    environment = {
      WAYLAND_DISPLAY="wayland-1";
      DISPLAY = ":0";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /home/aidanb/.config/kanshi/config'';
    };
  };

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

  # Example to try:
  # services.wayvnc = {
  #   enable = true;
  #   users = [ "aidanb" ];
  #   openFirewall = true;
  #   settings = { address = "0.0.0.0"; };
  # };

}

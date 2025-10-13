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
    ];

  };

  programs.waybar.enable = true;

}

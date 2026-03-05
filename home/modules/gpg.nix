{ config, pkgs, ... }:

{
  # GPG key management
  programs.gpg = {
    enable = true;
  };

  # GPG agent with Wayland-compatible pinentry
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-gnome3;
  };
}

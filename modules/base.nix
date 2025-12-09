{
  config,
  lib,
  pkgs,
  ...
}:

let
  basePackages = with pkgs; [
    pass
    htop
    git
    unzip
    wget
    vim
    neovim
    curl
    btop
    maim
    nix-index
    zstd
    smartmontools
    geeqie
    pciutils
    usbutils
  ];

in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  environment.systemPackages = basePackages;

  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

}

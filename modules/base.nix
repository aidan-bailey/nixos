{
  config,
  lib,
  pkgs,
  ...
}:

let
  basePackages = with pkgs; [
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
  ];

in
{

  environment.systemPackages = basePackages;

  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

}

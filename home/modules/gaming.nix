{ config, pkgs, ... }:

{
  # Gaming applications (user packages)
  # Steam system configuration is in modules/gaming.nix
  home.packages = with pkgs; [
    steam
    cockatrice
  ];
}


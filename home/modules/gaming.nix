{ config, pkgs, ... }:

{
  # Gaming applications (user packages)
  # Steam system configuration is in modules/gaming.nix
  home.packages = with pkgs; [
    steam
    (cockatrice.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "Cockatrice";
        repo = "Cockatrice";
        rev = "2026-02-22-Release-2.10.3";
        hash = "sha256-GQVdn6vUW0B9vSk7ZvSDqMNhLNe86C+/gE1n6wfQIMw=";
      };
    }))
  ];
}

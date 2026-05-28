{ config, pkgs, ... }:

{
  # Gaming applications (user packages).
  # Steam is installed system-wide via programs.steam in modules/gaming.nix —
  # adding pkgs.steam here would shadow it with an unwrapped copy on PATH and
  # silently drop extraCompatPackages (Proton-GE, vkd3d-proton).
  home.packages = with pkgs; [
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

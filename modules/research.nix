{
  config,
  lib,
  pkgs,
  ...
}:

let
  researchPackages = with pkgs; [
    texliveFull
    zotero
  ];

in
{

  environment.systemPackages = researchPackages;

}


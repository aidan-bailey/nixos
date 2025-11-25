{ config, pkgs, ... }:

{
  # Research tools and packages
  home.packages = with pkgs; [
    texliveFull
    zotero
    typst
    tinymist
  ];
}


{ config, pkgs, ... }:

{
  # Neovim editor configuration
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    # Add plugins and configuration as needed
    # plugins = with pkgs.vimPlugins; [ ];
    # extraConfig = '' '';
  };
}

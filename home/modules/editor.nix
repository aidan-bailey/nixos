{ config, pkgs, ... }:

{
  # Neovim editor configuration
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    
    # Add plugins and configuration as needed
    # plugins = with pkgs.vimPlugins; [ ];
    # extraConfig = '' '';
  };
}


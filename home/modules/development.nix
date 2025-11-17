{ config, pkgs, ... }:

{
  # Development tools and environment configuration
  
  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Session variables for development
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  
  # Development-related packages can be added here
  # home.packages = with pkgs; [ ];
}


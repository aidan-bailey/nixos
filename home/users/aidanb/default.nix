{ config, pkgs, ... }:

{
  # Modular Home Manager Configuration for aidanb
  # Reusable modules are in ../modules/
  # User-specific settings are defined here

  imports = [
    ../../modules/shell.nix
    ../../modules/terminal.nix
    ../../modules/editor.nix
    ../../modules/git.nix
    ../../modules/development.nix
    ../../modules/devtools.nix
    ../../modules/research.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/wayland.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "aidanb";
  home.homeDirectory = "/home/aidanb";

  programs.git.settings.user = {
    name = "Aidan Bailey";
    email = "dev@aidanbailey.me";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}


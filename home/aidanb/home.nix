{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.doom-flake.homeManagerModules.default
  ];

  home.username = "aidanb";
  home.homeDirectory = "/home/aidanb";

  home.stateVersion = "25.05"; # Required

  programs.git.enable = true;
  programs.zsh.enable = true;

  # Doom Emacs config comes from doom-flake
  programs.doom-emacs = {
    enable = true;
    emacsPackage = pkgs.emacs-pgtk.override { withNativeCompilation = true; };
    doomPrivateDir = inputs.doom-flake + "/doom-config";
  };
}

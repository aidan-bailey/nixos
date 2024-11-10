{
  config,
  lib,
  pkgs,
  ...
}:

{

  home.username = "aidanb";
  home.homeDirectory = "/home/aidanb";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
      yzhang.markdown-all-in-one
    ];
  };

}
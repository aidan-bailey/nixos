{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    alacritty
    zsh
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
      updaten = "sudo nixos-rebuild switch";
      configure = "nvim /etc/nixos/configuration.nix";
    };

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
  };

}

{ config, lib, pkgs, ... }:

{
  # Zsh shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    shellAliases = {
      ll = "ls -l";
      configure = "nvim /etc/nixos/configuration.nix";
      updaten = "sudo nixos-rebuild switch --flake ~/System#$HOST";
      hibernate = "sudo systemctl hibernate";
      shib = "systemd-inhibit sleep infinity";
      nix-sync-cache = "sudo nixos-rebuild switch --flake ~/System#$HOST --option extra-substituters \"file:///mnt/nixos-cache?priority=10\" --option require-sigs false && nix copy /run/current-system --to file:///mnt/nixos-cache";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

    initContent = ''
      # SSH Agent setup
      eval $(ssh-agent) > /dev/null 2> /dev/null
      ssh-add ~/.ssh/$HOST > /dev/null 2> /dev/null
      
      # Doom Emacs in PATH
      export PATH="/home/aidanb/.emacs.d/bin:$PATH"
      
      # Direnv integration
      eval "$(direnv hook zsh)"
    '';
  };
}


{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Zsh shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
      configure = "nvim /etc/nixos/configuration.nix";
      updaten = "sudo nixos-rebuild switch --flake ~/System#$HOST --option substitute false |& nom";
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
      if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l &>/dev/null; then
        eval $(ssh-agent) > /dev/null 2>/dev/null
        ssh-add ~/.ssh/$HOST > /dev/null 2>/dev/null
      fi

      # Doom Emacs in PATH
      export PATH="/home/aidanb/.emacs.d/bin:$PATH"

      # Set COLORTERM for truecolor-capable terminals (lost over SSH)
      if [ -z "$COLORTERM" ]; then
        case "$TERM" in
          alacritty*|*-256color) export COLORTERM="truecolor" ;;
        esac
      fi
    '';
  };
}

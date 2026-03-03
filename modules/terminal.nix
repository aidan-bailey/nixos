{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System-level terminal configuration
  # User-specific terminal configuration (zsh, alacritty, neovim) now managed via Home Manager

  # Enable zsh at system level (required for it to work as user shell)
  programs.zsh.enable = true;

  # Keep direnv at system level as it's often needed system-wide
  environment.systemPackages = with pkgs; [
    direnv
  ];

}

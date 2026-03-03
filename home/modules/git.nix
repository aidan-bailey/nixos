{ config, pkgs, ... }:

{
  # Git version control configuration
  programs.git = {
    enable = true;
    
    # Git settings (aliases and config merged)
    settings = {
      # Aliases
      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        graph = "log --graph --oneline --decorate --all";
      };
      
      # Configuration
      init.defaultBranch = "main";
      pull.rebase = false;
      # credential.helper = "store";
    };
  };
}


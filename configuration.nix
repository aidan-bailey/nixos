# Aidan's NixOS config

{ config, pkgs, callPackage, ... }:
{

  ##############
  # SYS CONFIG #
  ##############

  system.stateVersion = "23.05"; # Did you read the comment?

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "fresco"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;

  # Locale + TZ.
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";


  # GUI
  services.xserver = {
    enable = true;
    desktopManager = {xterm.enable=false;};
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
	i3lock
	i3blocks
      ];
    };
  };
  services.displayManager.defaultSession = "none+i3";
  programs.dconf.enable = true;
  services.picom = {
    enable = true;
    fade = false;
#    vSync = true;
    shadow = true;
    fadeDelta = 1 ;
    inactiveOpacity = 0.9;
    activeOpacity = 1;
#    backend = "glx";
    settings = {
      blur = {
	#method = "dual_kawase";
#	background = true;
	strength = 5;
      };
    };
  };


  # Keyboard
  services.xserver = {
    xkb = { 
    	layout = "za";
    	variant = ""; 
	options = "caps:swapescape";
    };
  };
  console.useXkbConfig = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Services
  services.openssh.enable = true;
  services.printing.enable = true; # enable CUPS to print documents
  services.emacs.package = pkgs.emacs-unstable;
  services.xserver.windowManager.i3.package = pkgs.i3-gaps;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  ############
  # PACKAGES #
  ############

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    }))
  ];

  # Terminal
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

  };

  environment.systemPackages = with pkgs; [
 	wget
	vim
	neovim
	curl
	htop
	git
	feh
	unzip
	rofi
	zsh
	pkgs.emacsGcc
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aidanb = {
    isNormalUser = true;
    description = "Aidan Bailey";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox
      thunderbird
	discord
	slack
	firefox
	alacritty
    ];
  };

}

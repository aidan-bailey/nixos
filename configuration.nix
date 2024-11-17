# Aidan's NixOS config

{
  config,
  pkgs,
  callPackage,
  ...
}:
let
  basePackages = with pkgs; [
    wget
    vim
    neovim
    curl
    htop
    git
    unzip
    zsh
    alacritty
    xfce.thunar
    home-manager
    smartmontools
    gparted
    nvme-cli
    ddrescue
    gnome.gnome-keyring
    geeqie
  ];

  guiPackages = with pkgs; [
    rofi
    feh
    lxappearance
    pavucontrol
    pa_applet
    networkmanagerapplet
    blueman
  ];

  devPackages = with pkgs; [
    # Essentials
    libtool
    cmake
    gnumake
    gcc
    stdenv
    # Shell
    shfmt
    shellcheck
    nodePackages.bash-language-server
    # Markdown
    python311Packages.grip
    pandoc
    marksman
    # Emacs
    ripgrep
    fd
    # Nix
    nixd
    nixfmt-rfc-style
    # JS
    nodejs_22
    # DB
    postgresql
    dbeaver-bin
    # Emulation
    qemu
    libvirt
    swtpm
    guestfs-tools
    libosinfo
    # Python
    python3Full
    pyright
    pyenv
    semgrep
    python311Packages.black
    python311Packages.pyflakes
    python311Packages.isort
    python311Packages.pytest
    ruff
  ];

  apps = with pkgs; [
    firefox
    brave
    thunderbird
    discord
    firefox
    spotify
    steam
    cockatrice
  ];
  tools = with pkgs; [
    slack
    vscode
    pkgs.emacs-git
    remmina
    virt-manager
    clockify
    pomodoro-gtk
    protonvpn-gui
    bitwarden-desktop
    bitwarden-menu
  ];
in
{

  ##############
  # SYS CONFIG #
  ##############

  system.stateVersion = "23.05";

  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "postgres" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      local all all              trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = "options kvm_amd sev=1";

  # Networking
  networking.hostName = "fresco"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 22 ];
  networking.firewall.enable = false;
  networking.extraHosts =
  ''
    192.168.122.5 wesco
  '';

  # Bluetooth

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Graphics

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Locale + TZ.
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";

  # GUI
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
    };
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
    fadeDelta = 1;
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
    #jack.enable = true;
  };

  # RDP
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "i3";
  services.xrdp.openFirewall = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # Services
  services.printing.enable = true; # enable CUPS to print documents
  services.xserver.windowManager.i3.package = pkgs.i3-gaps;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
  services.gnome.gnome-keyring.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  # Virtualisation
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  ############
  # PACKAGES #
  ############

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (
      builtins.fetchTarball {
        url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
      }
    ))
  ];

  programs.nix-ld.enable = true;

  # Terminal
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
      updaten = "sudo nixos-rebuild switch";
      updateh = "home-manager switch";
      configure = "nvim /etc/nixos/configuration.nix";
    };

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  environment.systemPackages = basePackages ++ guiPackages ++ devPackages;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aidanb = {
    isNormalUser = true;
    description = "Aidan Bailey";
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    packages = apps ++ tools;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHEbjAttdt+o26cZKZdfec8Bm1xuuE/2ToNXozF9PIgS aidanb@fresco"
    ];
  };

}

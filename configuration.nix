# Aidan's NixOS config — Wayland/Sway

{
  config,
  pkgs,
  lib,
  inputs,
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
    smartmontools
    zoom-us
    gparted
    nvme-cli
    ddrescue
    geeqie
    zstd
    nix-index
    wdisplays
    maim
    btop
    glmark2
    radeontop
    libva
    glxinfo
    lact
    brightnessctl
  ];

  guiPackages = with pkgs; [
    # Wayland-friendly replacements
    wofi # replaces rofi
    swaybg # replaces feh for wallpapers
    lxappearance
    pavucontrol
    networkmanagerapplet
    blueman
    vlc
    kanshi # display profiles
    wlr-randr # quick output changes
    # arandr removed (XRandR/X11-only)
  ];

  devPackages = with pkgs; [
    # Essentials
    direnv
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
    uv
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
    virtiofsd
    # Python
    python3 #Full
    pyright
    pyenv
    semgrep
    pipenv
    ruff
    # XML
    libxslt
    # Rust
    #cargo
    rustup
    lldb
    #rust-analyzer
    #rustc
    #cargo
    #rustfmt
    #clippy
    # Nix
    nixfmt-rfc-style
  ];

  apps = with pkgs; [
    brave
    vivaldi
    thunderbird
    protonmail-bridge
    discord
    firefox
    spotify
    steam
    gamescope
    cockatrice
  ];

  tools = with pkgs; [
    mupdf
    qbittorrent-enhanced
    slack
    vscode
    pkgs.emacs-git-pgtk
    remmina
    virt-manager
    clockify
    pomodoro-gtk
    protonvpn-gui
    bitwarden-desktop
    bitwarden-menu
    waybar # panel for sway
    swayidle
    swaylock
    grim
    slurp # screenshots on Wayland
    wl-clipboard # wl-copy / wl-paste
    mako # Wayland notifications
    # Cursor
    code-cursor
    element-desktop
    teamviewer
  ];

  scripts = [ 
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '')
    ];

in
{

  ##############
  # SYS CONFIG #
  ##############

  system.stateVersion = "25.05";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
      "amd_pstate=active"
      "amdgpu.dc=1"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
  };
  environment.pathsToLink = [ "/libexec" ];
  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  #system.autoUpgrade.channel = "https://channels.nixos.org/nixos-25.05";

  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = "options kvm_amd sev=1";

  ##############
  # NETWORKING #
  ##############

  networking = {
    networkmanager.enable = true;
    hostName = "nesco";
    extraHosts = ''
    192.168.122.23 winesco
    '';
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
	#137 138 139 445 # SAMBA
      ];
      allowedUDPPorts = [
      	22 # SSH
	#137 138 # SAMBA
      ];
    };
  };

  # - bluetooth - #
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # - SSH - #
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true; # harmless w/ Wayland, for remote X11 apps
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  #########
  # POWER #
  #########

  powerManagement.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      #CPU_MIN_PERF_ON_AC = 0;
      #CPU_MAX_PERF_ON_AC = 100;
      #CPU_MIN_PERF_ON_BAT = 0;
      #CPU_MAX_PERF_ON_BAT = 20;
      # optional battery thresholds:
      # START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  ###############
  # HIBERNATION #
  ###############

  systemd.sleep.extraConfig = ''
    [Sleep]
    HibernateMode=shutdown
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    AllowHybridSleep=no
    HibernateDelaySec=20min
  '';

  systemd.services.hibernate-on-low-battery = {
    description = "Hibernate when battery critically low";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /bin/sh -c '
          CAP_FILE=/sys/class/power_supply/BAT0/capacity
          STAT_FILE=/sys/class/power_supply/BAT0/status
          [ -r "$CAP_FILE" ] || exit 0
          CAP=$(cat "$CAP_FILE")
          STAT=$(cat "$STAT_FILE" 2>/dev/null || echo Unknown)
          if [ "$STAT" = "Discharging" ] && [ "$CAP" -le 5 ]; then
            systemctl hibernate
          fi
        '
      '';
    };
  };

  systemd.timers.hibernate-on-low-battery = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
      AccuracySec = "30s";
    };
  };

  # Script to unload/load Wi-Fi around sleep/hibernate
  environment.etc."systemd/system-sleep/mt7925e".text = ''
    #!/bin/sh
    case "$1" in
      pre)
        # Bring down networking cleanly (optional but nice)
        ${pkgs.networkmanager}/bin/nmcli radio wifi off 2>/dev/null || true
        # Unload the MT7925e Wi-Fi module (the one that times out)
        ${pkgs.kmod}/bin/modprobe -r mt7925e || true
        ;;
      post)
        # Reload after resume
        ${pkgs.kmod}/bin/modprobe mt7925e || true
        # Let NetworkManager re-associate
        ${pkgs.networkmanager}/bin/nmcli radio wifi on 2>/dev/null || true
        ;;
    esac
  '';
  environment.etc."systemd/system-sleep/mt7925e".mode = "0755";

  boot.resumeDevice = "/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609";

  services.logind.settings.Login = {
    lidSwitch = "hibernate";
    lidSwitchExternalPower = "suspend-then-hibernate";
    extraConfig = ''
        # If some apps inhibit sleep, ignore the inhibitor on lid close:
        LidSwitchIgnoreInhibited=yes
        # If you want a delay when using suspend-then-hibernate:
        HibernateDelaySec=10min
      	IdleAction=suspend-then-hibernate
      	IdleActionSec=30min
    '';
  };

  # In your configuration.nix
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };

  #########
  # USERS #
  #########

  services.getty = {
    autologinUser = "aidanb";
    autologinOnce = true;
  };
  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  ############
  # GRAPHICS #
  ############

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libvdpau-va-gl
      vaapiVdpau
    ];
  };
  services.picom.enable = lib.mkForce false;

  # Locale + TZ.
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";
  environment.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    NIXOS_OZONE_WL = "1";
  };

  ################
  # WAYLAND/SWAY #
  ################

  services.xserver.enable = false;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    xwayland.enable = true;
    extraSessionCommands = "
    	export XDG_CURRENT_DESKTOP=sway
	    export XDG_SESSION_DESKTOP=sway
    ";

    extraPackages = with pkgs; [
      waybar
      swaybg
      swayidle
      swaylock
      wofi
      kanshi
      wlr-randr
      grim
      slurp
      wl-clipboard
      mako
      xdg-desktop-portal-wlr
    ];

  };

  # kanshi systemd service
  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    #environment = {
    #  WAYLAND_DISPLAY="wayland-1";
    #  DISPLAY = ":0";
    #};
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /home/aidanb/.config/kanshi/config'';
    };
  };
  programs.waybar.enable = true;

  # Portals for Wayland (screensharing, file dialogs)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.polkit.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  # Keyboard layout (exports XKB_* for Wayland too)
  services.xserver.xkb = {
    layout = "za";
    variant = "";
    options = "caps:swapescape";
  };
  console.useXkbConfig = true;

  programs.firefox.package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {
  pipewireSupport = true;
}) {};

  #########
  # AUDIO #
  #########

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # RDP: xrdp is Xorg-based. Consider wayvnc for Wayland remote desktop.
  services.xrdp.enable = lib.mkForce false;
  # Example to try:
  # services.wayvnc = {
  #   enable = true;
  #   users = [ "aidanb" ];
  #   openFirewall = true;
  #   settings = { address = "0.0.0.0"; };
  # };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.noto
  ];

  # Services
  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

  ##################
  # VIRTUALISATION #
  ##################

  # Enable Samba server
  services.samba = {
    enable = true;
    settings = {
      vmshare = {
        path = "/srv/vm-shared";
        browseable = true;
        "read only" = false;
        "guest ok" = true;			
	"create mask" = "0666";      # permissions for new files
        "directory mask" = "0777";   # permissions for new folders
      };
    };
  };

  system.activationScripts.createVmShare = {
    text = ''
      mkdir -p /srv/vm-shared
      chmod 777 /srv/vm-shared
    '';
  };

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  services.avahi = {
     enable = true;
     publish = {
     	enable = true;
	userServices = true;
     };
  };


  ############
  # PACKAGES #
  ############

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (
      builtins.fetchTarball {
        # pin emacs overlay as you had it
        url = "https://github.com/nix-community/emacs-overlay/archive/29430cce2da82c0f658cd3310191434bf709f245.tar.gz";
        sha256 = "02l1f9d3qr634ja32psj63938wh0lp87fpnkgcmk7a82vpbk3qjh";
      }
    ))
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      glib
      libGL
      libxkbcommon
      fontconfig
      xorg.libX11 # keep for some legacy apps (via XWayland)
      freetype
      dbus
      libkrb5
      krb5
      libpulseaudio
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilwm
      xorg.xcbutilcursor # this is the “xcb-cursor0 / libxcb-cursor0” that Qt demands
      # NEW: PipeWire for QtMultimedia (6.9 tries pipewire-0.3)
      pipewire
      # Wayland client libs (helpful even if you use xcb via XWayland sometimes)
      wayland
      wayland-protocols
      # Optional but sometimes needed for decorations on Wayland:
      libdecor
    ];
  };

  # Terminal + zsh
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

  #########
  # STEAM #
  #########

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
      pkgs.vkd3d-proton
    ];
  };

  environment.systemPackages = basePackages ++ guiPackages ++ devPackages ++ scripts;

  # User
  users.users.aidanb = {
    isNormalUser = true;
    description = "Aidan Bailey";
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "wheel"
      # "input" "video" # add if some Wayland apps complain about permissions
    ];
    shell = pkgs.zsh;
    packages = apps ++ tools;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOX/kOPgPyOn9iJ5YhPK9+F2Ek9YaYqvrA6k2Ki+ALQ1 aidanb@nesco"
    ];
  };

}

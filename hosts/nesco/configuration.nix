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
  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
  ];
  environment.pathsToLink = [ "/libexec" ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/sway.nix
    ../../modules/apps.nix
    ../../modules/audio.nix
    ../../modules/terminal.nix
    ../../modules/bluetooth.nix
    ../../modules/networking.nix
    ../../modules/user.nix
    ../../modules/gaming.nix
    ../../modules/devtools.nix
    ../../modules/virtualisation.nix
    ../../modules/zenbook_s16/power.nix
    ../../modules/amd/cpu.nix
    ../../modules/amd/graphics.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = basePackages ++ scripts;

}

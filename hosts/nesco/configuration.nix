# Aidan's NixOS config — Wayland/Sway

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let

in
{

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
    ../../modules/kernel/cachyos.nix
    ../../modules/amd/cpu.nix
    ../../modules/amd/zen5.nix
    ../../modules/amd/graphics.nix
  ];

  nix.settings.system-features = [ "gccarch-znver5" "benchmark" "big-parallel" "kvm" "nixos-test" ];

  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
  ];

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver5";
    gcc.tune = "znver5";
  };

  environment.sessionVariables = {
    RUSTFLAGS = "-C target-cpu=znver5 -C link-arg=-flto";
    GOAMD64 = "v4";
  };

  environment = {
    pathsToLink = [ "/libexec" ];
    systemPackages = [
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '')

    ];
  };

}

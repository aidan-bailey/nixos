{
  config,
  lib,
  pkgs,
  ...
}:

let
  basePackages = with pkgs; [
    pass
    htop
    git
    unzip
    wget
    vim
    neovim
    curl
    btop
    maim
    nix-index
    zstd
    smartmontools
    geeqie
    pciutils
    usbutils
  ];

in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Compress initrd with zstd for faster boot
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [
    "-19"
    "-T0"
  ];

  environment.systemPackages = basePackages;

  # Compressed swap in RAM (reduces disk swap, improves responsiveness)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Use tmpfs for /tmp (faster, avoids disk writes)
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
  };

  # Automatic Nix store garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.printing.enable = true; # CUPS
  services.gvfs.enable = true; # Mount, trash, etc
  services.tumbler.enable = true; # Thumbnails

}

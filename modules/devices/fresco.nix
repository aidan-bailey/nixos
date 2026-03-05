{
  config,
  lib,
  pkgs,
  ...
}:

{

  # Zen 4 LTO kernel — compiled with -march=znver4 via Clang + ThinLTO
  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

  imports = [
    ../nvidia/gpu.nix
    ../amd/zen4.nix
    ../tuning/workstation.nix
    ../tuning/network.nix
    ../tuning/io.nix
  ];

  custom.hostType = "desktop";
  custom.display.type = "lcd";

  networking.hostName = "fresco";

  nix.settings.system-features = [
    "gccarch-znver4"
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

  # Sway NVIDIA support
  programs.sway.extraOptions = [ "--unsupported-gpu" ];

  # B650M Mortar WiFi (MT7922/mt7921e) — disable ASPM for stability
  boot.extraModprobeConfig = "options mt7921e disable_aspm=1";

  # Nix build tuning for 8-core workstation
  nix.settings = {
    max-jobs = 4;
    cores = 4;
    auto-optimise-store = true;
    keep-outputs = true;
    keep-derivations = true;
  };

  # EXT4 mount tuning
  fileSystems."/".options = [
    "noatime"
    "commit=60"
  ];
  fileSystems."/tb".options = [
    "noatime"
    "commit=60"
  ];

}

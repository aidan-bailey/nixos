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

  # RTX 3070 GAMING X TRIO overclock: 2000MHz core / 8000MHz mem / 250W
  systemd.services.gpu-overclock = {
    description = "Apply RTX 3070 GAMING X TRIO overclock";
    after = [ "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "apply-3070-oc" ''
        smi=${config.hardware.nvidia.package.bin}/bin/nvidia-smi
        $smi -lgc 2000,2000
        $smi -pl 250
        ${pkgs.python3.withPackages (ps: [ ps.nvidia-ml-py ])}/bin/python3 -c \
          "from pynvml import *; nvmlInit(); h = nvmlDeviceGetHandleByIndex(0); nvmlDeviceSetMemClkVfOffset(h, 2000);"
      '';
    };
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

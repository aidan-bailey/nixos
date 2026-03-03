{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    ../nvidia/gpu.nix
    ../amd/zen4.nix
  ];

  networking.hostName = "fresco";

  nix.settings.system-features = [ "gccarch-znver4" "benchmark" "big-parallel" "kvm" "nixos-test" ];

  # Sway NVIDIA support
  programs.sway.extraOptions = [ "--unsupported-gpu" ];

  # Desktop power: disable TLP laptop power management, use performance governor
  services.tlp.enable = lib.mkForce false;
  powerManagement.cpuFreqGovernor = "performance";

  # LCD font rendering (override OLED defaults from sway.nix)
  fonts.fontconfig.subpixel = {
    rgba = lib.mkForce "rgb";
    lcdfilter = lib.mkForce "default";
  };

  # B650M Mortar WiFi (MT7922/mt7921e) — disable ASPM for stability
  boot.extraModprobeConfig = "options mt7921e disable_aspm=1";

  boot.kernelParams = [
    "mitigations=off"
    "transparent_hugepage=madvise"
  ];

  # Nix build tuning for 8-core workstation
  nix.settings = {
    max-jobs = 4;
    cores = 4;
    auto-optimise-store = true;
    keep-outputs = true;
    keep-derivations = true;
  };

  # sysctl tuning for zram + compilation workloads
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "kernel.sched_autogroup_enabled" = 1;
  };

  # NVMe I/O scheduler: none (NVMe has internal scheduling)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # OOM protection
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = [
      "--prefer" "^(cc1|cc1plus|ld|rustc|cargo)$"
      "--avoid" "^(sway|waybar|firefox|emacs)$"
    ];
  };

  # EXT4 noatime on root
  fileSystems."/".options = [ "noatime" ];

}

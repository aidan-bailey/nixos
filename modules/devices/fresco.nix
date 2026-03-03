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

  nix.settings.system-features = [
    "gccarch-znver4"
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

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
    "transparent_hugepage=madvise"
    "iommu=pt" # passthrough mode — reduces IOMMU overhead for direct device access
    "split_lock_detect=off" # avoid performance penalty from split-lock #AC exceptions
    "workqueue.power_efficient=0" # prefer performance over power saving for workqueues
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
    "kernel.nmi_watchdog" = 0; # disable NMI watchdog — saves a perf counter and reduces overhead
    "vm.max_map_count" = 1048576; # needed by some games/apps (e.g. Star Citizen, Electron)
    "vm.compaction_proactiveness" = 0; # disable proactive compaction — reduces latency spikes
    "vm.watermark_boost_factor" = 0; # disable watermark boosting — avoids unnecessary reclaim
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
      "--prefer"
      "^(cc1|cc1plus|ld|rustc|cargo)$"
      "--avoid"
      "^(sway|waybar|firefox|emacs)$"
    ];
  };

  # IRQ balancing across cores (with NixOS ProtectKernelTunables workaround)
  services.irqbalance.enable = true;
  systemd.services.irqbalance.serviceConfig.ProtectKernelTunables = lib.mkForce false;

  # Force AMD EPP to performance on all cores at boot
  systemd.tmpfiles.rules = [
    "w /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference - - - - performance"
  ];

  # EXT4 noatime on root
  fileSystems."/".options = [ "noatime" ];

}

{
  config,
  lib,
  pkgs,
  ...
}:

{

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    "iommu=pt" # passthrough mode — reduces IOMMU overhead for direct device access
    "split_lock_detect=off" # avoid performance penalty from split-lock #AC exceptions
    "workqueue.power_efficient=0" # prefer performance over power saving for workqueues
  ];

  # VM and kernel sysctls for zram + compilation workloads
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

  # Force AMD EPP to performance on all cores at boot
  systemd.tmpfiles.rules = [
    "w /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference - - - - performance"
  ];

  # IRQ balancing across cores (with NixOS ProtectKernelTunables workaround)
  services.irqbalance.enable = true;
  systemd.services.irqbalance.serviceConfig.ProtectKernelTunables = lib.mkForce false;

  # sched-ext BPF userspace scheduler — better latency under mixed workloads
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # Nix daemon scheduling — lower priority to avoid starving desktop
  nix.daemonCPUSchedPolicy = "batch";
  nix.daemonIOSchedClass = "best-effort";
  nix.daemonIOSchedPriority = 7;

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

  # Journal size limits
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

}

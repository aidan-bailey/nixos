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
    # TCP/network performance
    "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR — better throughput and latency
    "net.core.default_qdisc" = "fq"; # fair queueing — required by BBR
    "net.ipv4.tcp_fastopen" = 3; # TFO for client and server — reduces connection latency
    "net.core.rmem_max" = 16777216; # 16 MB receive buffer max
    "net.core.wmem_max" = 16777216; # 16 MB send buffer max
    "net.ipv4.tcp_rmem" = "4096 131072 16777216"; # min/default/max receive buffer
    "net.ipv4.tcp_wmem" = "4096 65536 16777216"; # min/default/max send buffer
  };

  # NVMe I/O scheduler: none (NVMe has internal scheduling)
  # WiFi RPS: spread rx across all 8 cores (0xff)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="wl*", ATTR{queues/rx-0/rps_cpus}="ff"
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

  # EXT4 mount tuning
  fileSystems."/".options = [
    "noatime"
    "commit=60"
  ];
  fileSystems."/tb".options = [
    "noatime"
    "commit=60"
  ];

  # Weekly TRIM for NVMe longevity
  services.fstrim.enable = true;

  # Nix daemon scheduling — lower priority to avoid starving desktop
  nix.daemonCPUSchedPolicy = "batch";
  nix.daemonIOSchedClass = "best-effort";
  nix.daemonIOSchedPriority = 7;

  # Journal size limits
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

}

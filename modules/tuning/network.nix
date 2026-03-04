{
  config,
  lib,
  pkgs,
  ...
}:

{

  # TCP/network performance sysctls
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR — better throughput and latency
    "net.core.default_qdisc" = "fq"; # fair queueing — required by BBR
    "net.ipv4.tcp_fastopen" = 3; # TFO for client and server — reduces connection latency
    "net.core.rmem_max" = 16777216; # 16 MB receive buffer max
    "net.core.wmem_max" = 16777216; # 16 MB send buffer max
    "net.ipv4.tcp_rmem" = "4096 131072 16777216"; # min/default/max receive buffer
    "net.ipv4.tcp_wmem" = "4096 65536 16777216"; # min/default/max send buffer
  };

  # WiFi RPS: spread rx across all cores
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="wl*", ATTR{queues/rx-0/rps_cpus}="ff"
  '';

}

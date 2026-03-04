{
  config,
  lib,
  pkgs,
  ...
}:

{

  # NVMe I/O scheduler: none (NVMe has internal scheduling)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # Weekly TRIM for NVMe longevity
  services.fstrim.enable = true;

}

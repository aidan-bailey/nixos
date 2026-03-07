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
    ../amd/graphics.nix
    ../amd/cpu.nix
  ];

  custom.hostType = "laptop";
  custom.display.type = "oled";

  nix.settings.system-features = [
    "gccarch-znver5"
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x600" # Disables Panel Self Refresh (Critical for Zenbook S16)
    "amdgpu.sg_display=0" # Fixes white/flashing screen artifacts (Recommended)
    "amdgpu.abmlevel=0" # Disable Adaptive Brightness Management — fixes OLED flicker
    "amdgpu.ip_block_mask=0xffffbfff" # Disable VPE — broken s2idle resume on Strix Point
    "rcutree.enable_rcu_lazy=1" # Batch RCU callbacks for 5-10% idle power savings
    "rcu_nocbs=all" # Offload RCU callbacks from all CPUs
  ];

  # Hibernate config — use shutdown mode to avoid broken amdgpu S4 resume on Strix Point
  systemd.sleep.extraConfig = ''
    [Sleep]
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
    SuspendState=freeze
    HibernateMode=shutdown
  '';

  # Direct hibernate on lid close — suspend-then-hibernate crashes on Strix Point
  # due to broken s2idle resume (amdgpu VPE ring test failure)
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    LidSwitchIgnoreInhibited = "yes";
    IdleAction = "suspend";
    IdleActionSec = "30min";
  };

  # ASUS-specific daemon (fan profiles, platform profile switching)
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

}

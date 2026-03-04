{
  config,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    ../amd/graphics.nix
    ../amd/cpu.nix
  ];

  chaotic.hdr.enable = true;



  # Device-specific resume partition
  boot.resumeDevice = "/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609";

  nix.settings.system-features = [ "gccarch-znver5" "benchmark" "big-parallel" "kvm" "nixos-test" ];

  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
    "amdgpu.dcdebugmask=0x600"   # Disables Panel Self Refresh (Critical for Zenbook S16)
    "amdgpu.sg_display=0"        # Fixes white/flashing screen artifacts (Recommended)
    "amdgpu.ip_block_mask=0xffffbfff"  # Disable VPE — broken s2idle resume on Strix Point
    "rcutree.enable_rcu_lazy=1"  # Batch RCU callbacks for 5-10% idle power savings
    "rcu_nocbs=all"              # Offload RCU callbacks from all CPUs
  ];

  # Enable hibernate and suspend-then-hibernate (overrides power.nix defaults)
  systemd.sleep.extraConfig = lib.mkForce ''
    [Sleep]
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    AllowHybridSleep=no
    SuspendState=freeze
    HibernateDelaySec=30min
  '';

  # Suspend-then-hibernate on lid close (overrides power.nix defaults)
  services.logind.settings.Login = lib.mkForce {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
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

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
    "rcutree.enable_rcu_lazy=1"  # Batch RCU callbacks for 5-10% idle power savings
    "rcu_nocbs=all"              # Offload RCU callbacks from all CPUs
  ];

  # ASUS-specific daemon (fan profiles, platform profile switching)
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

}

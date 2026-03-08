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
    ../tuning/workstation.nix
    ../tuning/network.nix
    ../tuning/io.nix
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

  # RTX 3070 GAMING X TRIO overclock via NVML V-F curve offsets + 250W PL
  systemd.services.gpu-overclock = {
    description = "Apply RTX 3070 GAMING X TRIO overclock";
    after = [ "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          python = pkgs.python3.withPackages (ps: [ ps.nvidia-ml-py ]);
          smi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
        in
        pkgs.writeShellScript "apply-3070-oc" ''
                  set -euo pipefail
                  echo "Applying RTX 3070 overclock..." >&2
                  ${smi} -pl 250
                  ${python}/bin/python3 << 'PYEOF'
          import sys
          from pynvml import *

          try:
              nvmlInit()
              handle = nvmlDeviceGetHandleByIndex(0)

              # Memory offset: +1000MHz effective (units = MHz * 2 for GDDR6 on Ampere)
              nvmlDeviceSetMemClkVfOffset(handle, 2000)

              # Core/GPC offset: +50MHz on the V-F curve (units = MHz * 2)
              nvmlDeviceSetGpcClkVfOffset(handle, 100)

              print("RTX 3070 Overclock Applied: +50MHz Core / +1000MHz Mem")
              nvmlShutdown()
          except NVMLError as err:
              print(f"NVML Error: {err}")
              sys.exit(1)
          PYEOF
                  echo "GPU overclock applied successfully" >&2
        '';
    };
  };

  # Remote builder: allow nesco to offload builds to fresco
  users.users.nixremote = {
    isSystemUser = true;
    group = "nixremote";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMiW07jb+Pm26IisdAd3mWZ4oEdDKnSv9c7IIHWp0cvX nesco-builder"
    ];
  };
  users.groups.nixremote = { };

  nix.settings.trusted-users = [ "nixremote" ];

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

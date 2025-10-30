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

  # Script to unload/load Wi-Fi around sleep/hibernate
  # Specific to MT7925e Wi-Fi module in Zenbook S16
  environment.etc."systemd/system-sleep/mt7925e".text = ''
    #!/bin/sh
    case "$1" in
      pre)
        # Bring down networking cleanly (optional but nice)
        ${pkgs.networkmanager}/bin/nmcli radio wifi off 2>/dev/null || true
        # Unload the MT7925e Wi-Fi module (the one that times out)
        ${pkgs.kmod}/bin/modprobe -r mt7925e || true
        ;;
      post)
        # Reload after resume
        ${pkgs.kmod}/bin/modprobe mt7925e || true
        # Let NetworkManager re-associate
        ${pkgs.networkmanager}/bin/nmcli radio wifi on 2>/dev/null || true
        ;;
    esac
  '';
  environment.etc."systemd/system-sleep/mt7925e".mode = "0755";

  # Device-specific resume partition
  boot.resumeDevice = "/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609";

  nix.settings.system-features = [ "gccarch-znver5" "benchmark" "big-parallel" "kvm" "nixos-test" ];

  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
  ];

}

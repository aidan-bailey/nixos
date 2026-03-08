{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/zenbook_s16.nix
  ];

  custom.hostType = "laptop";
  custom.display.type = "oled";

  # Resume from swap partition (host-specific UUID)
  boot.resumeDevice = "/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609";
  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
  ];

  # Distributed builds: offload to fresco
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;
  nix.buildMachines = [
    {
      hostName = "fresco";
      sshUser = "nixremote";
      sshKey = "/root/.ssh/nix-remote-builder";
      protocol = "ssh-ng";
      systems = [ "x86_64-linux" ];
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [
        "big-parallel"
        "kvm"
        "nixos-test"
        "benchmark"
      ];
    }
  ];

  programs.ssh.knownHosts.fresco = {
    hostNames = [
      "fresco"
      "192.168.68.65"
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKv+POoler+pi2qglHw5nxu90Xql1ndd0x6BR2EAEmk6";
  };

  home-manager.users.aidanb.imports = [ ../../home/hosts/nesco.nix ];
}

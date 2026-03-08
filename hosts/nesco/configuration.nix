{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/zenbook_s16.nix
  ];

  # Resume from swap partition (host-specific UUID)
  boot.resumeDevice = "/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609";
  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/8debf292-09a9-44aa-a9db-6a556aefb609"
  ];

  networking.extraHosts = ''
    192.168.68.65 fresco
  '';

  home-manager.users.aidanb.imports = [ ../../home/hosts/nesco.nix ];
}

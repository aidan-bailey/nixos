{
  config,
  lib,
  pkgs,
  ...
}:

{

  networking = {
    networkmanager.enable = true;
    hostName = lib.mkDefault "nesco";
    extraHosts = ''
      192.168.122.23 winesco
    '';
    nftables.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
      ];
    };
  };

  # Encrypted DNS (opportunistic DoT, falls back on captive portals)
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    dnsovertls = "opportunistic";
    fallbackDns = [
      "1.1.1.1"
      "9.9.9.9"
      "2606:4700:4700::1111"
      "2620:fe::fe"
    ];
  };

  # Local network service discovery (.local hostnames)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

}

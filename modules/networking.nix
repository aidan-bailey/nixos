{
  config,
  lib,
  pkgs,
  ...
}:

{

  networking = {
    networkmanager = {
      enable = true;
      wifi.powersave = false; # disable WiFi power saving — reduces latency
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    hostName = lib.mkDefault "nesco";
    extraHosts = ''
      192.168.122.23 winesco
      192.168.68.65 fresco
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
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "1.1.1.1"
        "9.9.9.9"
        "2606:4700:4700::1111"
        "2620:fe::fe"
      ];
    };
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
      AcceptEnv = [
        "COLORTERM"
        "TERM_PROGRAM"
      ];
    };
    openFirewall = true;
  };

}

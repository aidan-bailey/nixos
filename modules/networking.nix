{
  config,
  lib,
  pkgs,
  ...
}:

{

  networking = {
    networkmanager.enable = true;
    hostName = "nesco";
    extraHosts = ''
      192.168.122.23 winesco
    '';
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        #137 138 139 445 # SAMBA
      ];
      allowedUDPPorts = [
        22 # SSH
        #137 138 # SAMBA
      ];
    };
  };

  # - SSH - #
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true; # harmless w/ Wayland, for remote X11 apps
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

}

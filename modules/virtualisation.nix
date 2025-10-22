{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    virt-manager
    docker
    docker-compose
    docker-buildx
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
  };


  # Enable Samba server
  services.samba = {
    enable = true;
    settings = {
      vmshare = {
        path = "/srv/vm-shared";
        browseable = true;
        "read only" = false;
        "guest ok" = true;
        "create mask" = "0666"; # permissions for new files
        "directory mask" = "0777"; # permissions for new folders
      };
    };
  };

  system.activationScripts.createVmShare = {
    text = ''
      mkdir -p /srv/vm-shared
      chmod 777 /srv/vm-shared
    '';
  };

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

}

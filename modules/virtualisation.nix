{
  config,
  lib,
  pkgs,
  ...
}:

let
  xenPatch = builtins.toFile "fix-xen.patch" ''
  diff --git a/xen/arch/x86/boot/Makefile b/xen/arch/x86/boot/Makefile
index d45787665907..80c32163fbbd 100644
--- a/xen/arch/x86/boot/Makefile
+++ b/xen/arch/x86/boot/Makefile
@@ -40,8 +40,8 @@ LD32 := $(LD) $(subst x86_64,i386,$(LDFLAGS_DIRECT))
 # are affected by both text_diff and text_gap.  Ensure the sum of gap and diff
 # is greater than 2^16 so that any 16bit relocations if present in the object
 # file turns into a build-time error.
-text_gap := 0x010200
-text_diff := 0x408020
+text_gap := 0x010240
+text_diff := 0x608040
 
 $(obj)/build32.base.lds: AFLAGS-y += -DGAP=$(text_gap) -DTEXT_DIFF=$(text_diff)
 $(obj)/build32.offset.lds: AFLAGS-y += -DGAP=$(text_gap) -DTEXT_DIFF=$(text_diff) -DAPPLY_OFFSET
--
  '';
in

{

  environment.systemPackages = with pkgs; [
    virt-manager
    docker
    docker-compose
    docker-buildx
  ];

  nixpkgs.overlays = [
	(final: prev: {
        xen = prev.xen.overrideAttrs (old: {
	  patches = (old.patches or []) ++ [ xenPatch ];
        });
      })
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

  virtualisation.xen.enable = false;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

}

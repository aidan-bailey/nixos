{
  config,
  lib,
  pkgs,
  ...
}:

{

  # Locale + TZ.
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";

  services.getty = {
    autologinUser = "aidanb";
    autologinOnce = true;
  };

  users.users.aidanb = {
    isNormalUser = true;
    description = "Aidan Bailey";
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "wheel"
      "docker"
      #"input"
      "video" # add if some Wayland apps complain about permissions
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHEbjAttdt+o26cZKZdfec8Bm1xuuE/2ToNXozF9PIgS aidanb@fresco"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOX/kOPgPyOn9iJ5YhPK9+F2Ek9YaYqvrA6k2Ki+ALQ1 aidanb@nesco"
    ];
  };

}

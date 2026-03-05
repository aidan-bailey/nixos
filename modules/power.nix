{
  config,
  lib,
  pkgs,
  ...
}:

{

  powerManagement.enable = true;

  # TLP is laptop-only — desktops manage power differently
  services.tlp = {
    enable = config.custom.hostType == "laptop";
    settings = {
      # CPU governor and EPP hints (amd-pstate-epp active mode)
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Turbo boost control
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # USB autosuspend
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_BTUSB = 1;

      # PCIe ASPM
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Runtime power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # ASUS charge threshold (only stop is supported)
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Conservative sleep defaults — device modules can override without mkForce
  systemd.sleep.extraConfig = lib.mkDefault ''
    [Sleep]
    AllowSuspend=yes
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  services.logind.settings.Login = lib.mkDefault {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    LidSwitchIgnoreInhibited = "yes";
    IdleAction = "suspend";
    IdleActionSec = "30min";
  };

}

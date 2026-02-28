{
  config,
  lib,
  pkgs,
  ...
}:

{

  powerManagement.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "power";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      #CPU_MIN_PERF_ON_AC = 0;
      #CPU_MAX_PERF_ON_AC = 100;
      #CPU_MIN_PERF_ON_BAT = 0;
      #CPU_MAX_PERF_ON_BAT = 20;
      # optional battery thresholds:
      # START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  systemd.sleep.extraConfig = ''
    [Sleep]
    HibernateMode=shutdown
    AllowSuspend=yes
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
    HibernateDelaySec=20min
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    LidSwitchIgnoreInhibited = "yes";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "30min";
  };

}

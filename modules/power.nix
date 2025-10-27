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
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
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
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    AllowHybridSleep=no
    HibernateDelaySec=20min
  '';

  systemd.services.hibernate-on-low-battery = {
    description = "Hibernate when battery critically low";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hibernate-on-low-battery" ''
        CAP_FILE=/sys/class/power_supply/BAT0/capacity
        STAT_FILE=/sys/class/power_supply/BAT0/status
        [ -r "$CAP_FILE" ] || exit 0
        CAP=$(cat "$CAP_FILE")
        STAT=$(cat "$STAT_FILE" 2>/dev/null || echo Unknown)
        if [ "$STAT" = "Discharging" ] && [ "$CAP" -le 5 ]; then
          systemctl hibernate
        fi
      '';
    };
  };

  systemd.timers.hibernate-on-low-battery = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
      AccuracySec = "30s";
    };
  };

  services.logind.settings.Login = {
    lidSwitch = "hibernate";
    lidSwitchExternalPower = "suspend-then-hibernate";
    extraConfig = ''
        # If some apps inhibit sleep, ignore the inhibitor on lid close:
        LidSwitchIgnoreInhibited=yes
        # If you want a delay when using suspend-then-hibernate:
      	IdleAction=suspend-then-hibernate
      	IdleActionSec=30min
    '';
  };

}


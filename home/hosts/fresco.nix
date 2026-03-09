{ ... }:
{
  imports = [ ../profiles/desktop.nix ];
  xdg.configFile."sway/config".source = ../../config/sway/fresco/config;

  custom.waybar.hostOverrides = {
    margin-bottom = 4;
    margin-left = 6;
    margin-right = 6;
    modules-right = [
      "custom/swaync"
      "mpd"
      "pulseaudio"
      "network"
      "disk"
      "custom/gpu"
      "cpu"
      "memory"
      "temperature"
      "idle_inhibitor"
      "tray"
      "custom/weather"
      "clock"
    ];

    temperature.critical-threshold = 90;

    disk = {
      interval = 30;
      format = "󰋊 {percentage_used}%";
      format-alt = "󰋊 {free}";
      path = "/";
      tooltip-format = "{path}\n{used} / {total} ({percentage_used}%)";
    };

    "custom/gpu" = {
      exec = "waybar-nvidiagpu";
      exec-if = "which nvidia-smi";
      return-type = "json";
      interval = 3;
      format = "{icon} {text}";
      format-icons = [
        "󰊴"
        "󰊴"
        "󰊴"
        "󰊴"
        "󰊴"
      ];
      tooltip = true;
      on-click = "alacritty -e btop";
    };
  };
}

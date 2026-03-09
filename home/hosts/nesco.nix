{ ... }:
{
  imports = [ ../profiles/desktop.nix ];
  xdg.configFile."sway/config".source = ../../config/sway/nesco/config;

  custom.waybar.hostOverrides = {
    margin-bottom = 8;
    margin-left = 12;
    margin-right = 12;
    modules-right = [
      "custom/swaync"
      "mpd"
      "pulseaudio"
      "network"
      "backlight"
      "battery"
      "custom/powerprofile"
      "custom/gpu"
      "cpu"
      "memory"
      "temperature"
      "idle_inhibitor"
      "tray"
      "custom/weather"
      "clock"
    ];

    temperature.critical-threshold = 85;

    backlight = {
      format = "{icon} {percent}%";
      format-icons = [
        "󰃞"
        "󰃞"
        "󰃞"
        "󰃟"
        "󰃟"
        "󰃟"
        "󰃠"
        "󰃠"
        "󰃠"
      ];
      on-scroll-up = "brightnessctl set +5%";
      on-scroll-down = "brightnessctl set 5%-";
      smooth-scrolling-threshold = 1;
    };

    battery = {
      states = {
        good = 80;
        warning = 30;
        critical = 15;
      };
      format = "{icon} {capacity}%";
      format-charging = "󰂄 {capacity}%";
      format-plugged = "󰚥 {capacity}%";
      format-full = "󰁹 Full";
      format-alt = "{icon} {time}";
      format-icons = [
        "󰁺"
        "󰁼"
        "󰁾"
        "󰂀"
        "󰁹"
      ];
      tooltip-format = "{timeTo}\nHealth: {health}%";
    };

    "custom/powerprofile" = {
      exec = "waybar-powerprofile";
      exec-if = "test -f /sys/firmware/acpi/platform_profile";
      return-type = "json";
      interval = 10;
      signal = 10;
      format = "{}";
      tooltip = true;
      on-click = "waybar-powerprofile-cycle";
    };

    "custom/gpu" = {
      exec = "waybar-amdgpu";
      exec-if = "which amdgpu_top";
      return-type = "json";
      interval = 3;
      format = "{icon} {text}";
      format-icons = [
        "󱐋"
        "󱐋"
        "󱐋"
        "󱐋"
        "󱐋"
      ];
      tooltip = true;
      on-click = "alacritty -e btop";
    };
  };
}

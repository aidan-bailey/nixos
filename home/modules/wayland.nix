{ config, pkgs, ... }:

{
  # Wayland user-specific configuration
  # System-level Wayland config is in modules/sway.nix

  # Wayland user packages
  home.packages = with pkgs; [
    waybar
    swaybg
    swayidle
    swaylock
    wofi
    kanshi
    wlr-randr
    slurp
    wl-clipboard
    cliphist
    swaynotificationcenter
    libnotify
    xdg-user-dirs
    xdg-desktop-portal-wlr
    networkmanagerapplet
    pavucontrol
    lxappearance
    wf-recorder
    grim
    gnome-keyring
    wdisplays
    brightnessctl
    gnome-themes-extra
    adwaita-icon-theme
    adwaita-qt
    wayvnc
    sway-audio-idle-inhibit
    polkit_gnome
    amdgpu_top
  ] ++ [
    # Waybar custom module scripts

    (pkgs.writeShellScriptBin "waybar-amdgpu" ''
      data=$(amdgpu_top --json -s 1000 -n 1 2>/dev/null)
      if [ -z "$data" ]; then
        printf '{"text":"N/A","class":"unavailable"}\n'
        exit 0
      fi
      ${pkgs.python3}/bin/python3 - "$data" <<'EOF'
import sys, json
d = json.loads(sys.argv[1])
dev = d.get("devices", [{}])[0]
pct = dev.get("gpu_activity", {}).get("GFX", {}).get("value", None)
used = dev.get("vram_usage", {}).get("Total VRAM Usage", {}).get("value", 0)
total = dev.get("vram_usage", {}).get("Total VRAM", {}).get("value", 1)
if pct is None:
    print('{"text":"N/A","class":"unavailable"}')
else:
    tip = f"AMD GFX: {pct}%\nVRAM: {used}/{total} MB"
    print(json.dumps({"text": f"{pct}%", "tooltip": tip, "percentage": int(pct), "class": "gpu"}))
EOF
    '')

    (pkgs.writeShellScriptBin "waybar-nvidiagpu" ''
      read -r gpu_pct mem_used mem_total temp < <(
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
                   --format=csv,noheader,nounits 2>/dev/null | tr ',' ' '
      )
      [ -z "$gpu_pct" ] && printf '{"text":"N/A","class":"unavailable"}\n' && exit 0
      gpu_pct=$(echo "$gpu_pct" | tr -d ' ')
      mem_used=$(echo "$mem_used" | tr -d ' ')
      mem_total=$(echo "$mem_total" | tr -d ' ')
      temp=$(echo "$temp" | tr -d ' ')
      tooltip="NVIDIA: ''${gpu_pct}%\nVRAM: ''${mem_used}/''${mem_total} MiB\nTemp: ''${temp}°C"
      printf '{"text":"%s%%","tooltip":"%s","percentage":%s,"class":"gpu"}\n' \
        "$gpu_pct" "$tooltip" "$gpu_pct"
    '')

    (pkgs.writeShellScriptBin "waybar-swaync" ''
      count=$(swaync-client -swb 2>/dev/null \
        | ${pkgs.python3}/bin/python3 -c \
          "import sys,json; d=json.load(sys.stdin); print(d.get('count',0))" 2>/dev/null || echo 0)
      dnd=$(swaync-client -D 2>/dev/null | tr -d '[:space:]' || echo false)
      if [ "$dnd" = "true" ]; then
        printf '{"text":"󰂛","tooltip":"DND on","class":"dnd"}\n'
      elif [ "$(( count + 0 ))" -gt 0 ] 2>/dev/null; then
        printf '{"text":"󰂞 %s","tooltip":"%s notifications","class":"notification"}\n' "$count" "$count"
      else
        printf '{"text":"󰂚","tooltip":"No notifications","class":"none"}\n'
      fi
    '')

    (pkgs.writeShellScriptBin "waybar-weather" ''
      lat="''${WAYBAR_WEATHER_LAT:--33.9}"
      lon="''${WAYBAR_WEATHER_LON:-18.4}"
      data=$(${pkgs.curl}/bin/curl -sf --max-time 10 \
        "https://api.open-meteo.com/v1/forecast?latitude=''${lat}&longitude=''${lon}&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,wind_speed_10m" \
        2>/dev/null)
      [ -z "$data" ] && printf '{"text":"󰖑 N/A","class":"unavailable"}\n' && exit 0
      ${pkgs.python3}/bin/python3 - "$data" <<'EOF'
import sys, json
d = json.loads(sys.argv[1])
c = d["current"]
code = c.get("weather_code", 0)
if code == 0: icon = "󰖙"
elif code in (1,2): icon = "󰖕"
elif code == 3: icon = "󰖐"
elif code in (45,48): icon = "󰖑"
elif code in (51,53,55,56,57,61,63,65,66,67,80,81,82): icon = "󰖗"
elif code in (71,73,75,77,85,86): icon = "󰼶"
elif code in (95,96,99): icon = "󰖓"
else: icon = "󰖑"
temp = c["temperature_2m"]
feels = c["apparent_temperature"]
hum = c["relative_humidity_2m"]
wind = c["wind_speed_10m"]
wmo = {0:"Clear",1:"Mainly clear",2:"Partly cloudy",3:"Overcast",45:"Fog",48:"Rime fog",
       51:"Light drizzle",53:"Drizzle",55:"Dense drizzle",56:"Freezing drizzle",57:"Dense freezing drizzle",
       61:"Light rain",63:"Rain",65:"Heavy rain",66:"Freezing rain",67:"Heavy freezing rain",
       71:"Light snow",73:"Snow",75:"Heavy snow",77:"Snow grains",
       80:"Light showers",81:"Showers",82:"Heavy showers",85:"Snow showers",86:"Heavy snow showers",
       95:"Thunderstorm",96:"Thunderstorm w/ hail",99:"Heavy thunderstorm w/ hail"}
desc = wmo.get(code, "Unknown")
tip = f"{desc}\n{temp}°C (feels {feels}°C)\nHumidity: {hum}%\nWind: {wind} km/h"
print(json.dumps({"text": f"{icon} {temp}°C", "tooltip": tip, "class": "weather"}))
EOF
    '')

    (pkgs.writeShellScriptBin "waybar-powerprofile" ''
      pf=/sys/firmware/acpi/platform_profile
      [ ! -f "$pf" ] && printf '{"text":"N/A","class":"unavailable"}\n' && exit 0
      profile=$(cat "$pf" | tr -d '[:space:]')
      case "$profile" in
        performance)             icon="󱐋"; class=performance ;;
        balanced*|balanced)      icon="󰾭"; class=balanced ;;
        low-power|power-saver|quiet) icon="󰔄"; class=power-saver ;;
        *)                       icon="󰾭"; class=balanced ;;
      esac
      printf '{"text":"%s %s","tooltip":"Profile: %s\nClick to cycle","class":"%s"}\n' \
        "$icon" "$profile" "$profile" "$class"
    '')

    (pkgs.writeShellScriptBin "waybar-powerprofile-cycle" ''
      if command -v asusctl >/dev/null 2>&1; then
        current=$(asusctl profile -p 2>/dev/null | awk '{print $NF}')
        case "$current" in
          Quiet)       asusctl profile -P Balanced ;;
          Balanced)    asusctl profile -P Performance ;;
          Performance) asusctl profile -P Quiet ;;
          *)           asusctl profile -P Balanced ;;
        esac
      fi
      pkill -RTMIN+10 waybar
    '')
  ];

  # HiDPI cursor (Adwaita at 1.5x = 36)
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 36;
    gtk.enable = true;
    x11.enable = true;
  };

  # Wayland session variables
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    CLUTTER_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    XCURSOR_SIZE = "36";
    WAYBAR_WEATHER_LAT = "-33.9";
    WAYBAR_WEATHER_LON = "18.4";
  };

  # Night light (color temperature adjustment)
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = -33.9;
    longitude = 18.4;
    temperature = {
      day = 6500;
      night = 3500;
    };
    tray = true;
  };

  # Waybar configuration — launched by Sway's bar block (swaybar_command),
  # so disable the systemd service to avoid a duplicate instance.
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  # Sway configuration (per-host config sourced from home/hosts/<host>.nix)
  xdg.configFile."sway/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

  # Waybar configuration
  xdg.configFile."waybar/config".source = ../../config/waybar/config;
  xdg.configFile."waybar/style.css".source = ../../config/waybar/style.css;

  # Polkit authentication agent for GUI privilege escalation
  systemd.user.services.polkit-gnome = {
    Unit = {
      Description = "PolicyKit Authentication Agent";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Configure XDG user directories
  # This sets up the standard directories (Pictures, Documents, etc.)
  # Customized to match your Media directory structure from init.sh
  # Note: XDG only supports standard directory types (PICTURES, MUSIC, etc.)
  # Custom directories like "screenshots" aren't part of the XDG spec
  xdg.userDirs = {
    enable = true;
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Media/Music";
    pictures = "${config.home.homeDirectory}/Media/Pictures";
    videos = "${config.home.homeDirectory}/Media/Videos";
    desktop = "${config.home.homeDirectory}/Desktop";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
  };

  # Custom environment variable for screenshots directory
  home.sessionVariables.SCREENSHOTS_DIR = "${config.home.homeDirectory}/Media/Pictures/Screenshots";

}

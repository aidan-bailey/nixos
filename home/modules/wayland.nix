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
      loc="''${WAYBAR_WEATHER_LOCATION:-}"
      data=$(${pkgs.curl}/bin/curl -sf --max-time 5 "https://wttr.in/''${loc}?format=j1" 2>/dev/null)
      [ -z "$data" ] && printf '{"text":"󰖑 N/A","class":"unavailable"}\n' && exit 0
      ${pkgs.python3}/bin/python3 - "$data" <<'EOF'
import sys, json
d = json.loads(sys.argv[1])
c = d["current_condition"][0]
code = int(c.get("weatherCode", 800))
if code == 113: icon = "󰖙"
elif code == 116: icon = "󰖕"
elif code in (119,122): icon = "󰖐"
elif code in (143,248,260): icon = "󰖑"
elif 176 <= code <= 359 and code not in (179,182,185,227,230,323,326,329,332,335,338,368,371,374,377): icon = "󰖗"
elif code in (179,182,185,227,230,323,326,329,332,335,338,368,371,374,377): icon = "󰼶"
elif code in (200,386,389,392,395): icon = "󰖓"
else: icon = "󰖑"
tip = f"{c['weatherDesc'][0]['value']}\n{c['temp_C']}°C (feels {c['FeelsLikeC']}°C)\nHumidity: {c['humidity']}%\nWind: {c['windspeedKmph']} km/h"
print(json.dumps({"text": f"{icon} {c['temp_C']}°C", "tooltip": tip, "class": "weather"}))
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
    WAYBAR_WEATHER_LOCATION = "Cape Town";
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

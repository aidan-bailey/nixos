{
  config,
  pkgs,
  lib,
  ...
}:

let
  location = {
    lat = "-33.9";
    lon = "18.4";
    latFloat = -33.9;
    lonFloat = 18.4;
  };

  waybarBase = {
    ipc = true;
    position = "bottom";
    height = 36;
    modules-left = [
      "sway/workspaces"
      "sway/mode"
      "sway/scratchpad"
    ];
    modules-center = [ "sway/window" ];

    "sway/workspaces" = {
      disable-scroll = false;
      all-outputs = false;
      format = "{name}";
    };

    "sway/mode" = {
      format = " {}";
    };

    "sway/scratchpad" = {
      format = "{icon} {count}";
      show-empty = false;
      format-icons = [
        ""
        ""
      ];
      tooltip = true;
      tooltip-format = "{app}: {title}";
    };

    "sway/window" = {
      max-length = 60;
      rewrite = {
        "(.*) — Mozilla Firefox" = "  $1";
        "(.*) - Zed" = "  $1";
        "foot" = " Terminal";
        "btop" = " btop";
        "ncmpcpp" = "󰎆 ncmpcpp";
      };
    };

    mpd = {
      format = "󰎆  {title} — {artist}  {stateIcon}";
      format-disconnected = "";
      format-stopped = "";
      unknown-tag = "?";
      interval = 2;
      state-icons = {
        paused = "󰏤";
        playing = "󰐊";
      };
      tooltip-format = "{title}\n{artist} — {album}\n[{songPosition}/{queueLength}] {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}";
      tooltip-format-disconnected = "MPD disconnected";
      on-click = "mpc toggle";
      on-click-right = "alacritty -e ncmpcpp";
      on-scroll-up = "mpc volume +2";
      on-scroll-down = "mpc volume -2";
      consume-icons = {
        on = "󰆤 ";
      };
      random-icons = {
        on = "󰒟 ";
      };
      repeat-icons = {
        on = "󰑖 ";
      };
      single-icons = {
        on = "󰑘 ";
      };
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰈈";
        deactivated = "󰈉";
      };
      tooltip-format-activated = "Idle inhibition ON";
      tooltip-format-deactivated = "Idle inhibition OFF";
    };

    tray = {
      spacing = 8;
      icon-size = 16;
    };

    clock = {
      format = "󰥔 {:%H:%M}";
      format-alt = "󰃭 {:%a %d %b}";
      tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
    };

    cpu = {
      format = "󰍛 {usage}% {avg_frequency}GHz";
      interval = 2;
      tooltip = true;
      on-click = "alacritty -e btop";
    };

    memory = {
      format = "󰒋 {used:.1f}G";
      format-alt = "󰒋 {percentage}%";
      interval = 5;
      tooltip-format = "RAM: {used:.1f}G / {total:.1f}G\nSwap: {swapUsed:.1f}G / {swapTotal:.1f}G";
      on-click = "alacritty -e btop";
    };

    temperature = {
      thermal-zone = 0;
      format = "󰔏 {temperatureC}°";
      format-critical = "󰔏 {temperatureC}°";
      tooltip = true;
    };

    network = {
      interval = 2;
      format-wifi = "󰖩 ↑{bandwidthUpBytes} ↓{bandwidthDownBytes}";
      format-ethernet = "󰈀 ↑{bandwidthUpBytes} ↓{bandwidthDownBytes}";
      format-linked = "󰈀 {ifname}";
      format-disconnected = "󰖪 Disconnected";
      format-alt = "󰖩 {essid} 󰒢 {signalStrength}%";
      tooltip-format-wifi = "{essid} 󰒢 {signalStrength}%\n{ipaddr}/{cidr}\n↑{bandwidthUpBytes} ↓{bandwidthDownBytes}";
      tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\n↑{bandwidthUpBytes} ↓{bandwidthDownBytes}";
      on-click-right = "alacritty -e nmtui";
    };

    pulseaudio = {
      scroll-step = 5;
      format = "{icon} {volume}%";
      format-bluetooth = "󰂯 {icon} {volume}%";
      format-bluetooth-muted = "󰂲 󰖁";
      format-muted = "󰖁";
      format-source = "󰍬 {volume}%";
      format-source-muted = "󰍭";
      format-icons = {
        headphone = "󰋋";
        hands-free = "󰋎";
        headset = "󰋎";
        phone = "󰏲";
        portable = "󰏲";
        car = "󰄋";
        default = [
          "󰕾"
          "󰕿"
          "󰖀"
        ];
      };
      on-click = "pavucontrol";
      on-click-right = "alacritty -e pw-top";
      tooltip-format = "{desc}\n{volume}%";
    };

    "custom/swaync" = {
      exec = "swaync-client -swb";
      exec-if = "which swaync-client";
      return-type = "json";
      format = "{icon}";
      format-icons = {
        none = "󰂚";
        notification = "󰂞";
        dnd-none = "󰂛";
        dnd-notification = "󰂛";
      };
      tooltip = true;
      on-click = "swaync-client -t -sw";
      on-click-right = "swaync-client -d -sw";
    };

    "custom/weather" = {
      exec = "waybar-weather";
      exec-if = "which curl";
      return-type = "json";
      interval = 1800;
      format = "{}";
      tooltip = true;
    };
  };
in
{
  options.custom.waybar = {
    base = lib.mkOption {
      type = lib.types.attrs;
      default = waybarBase;
      readOnly = true;
      description = "Base Waybar configuration shared across all hosts.";
    };

    hostOverrides = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Per-host Waybar overrides merged on top of the base config.";
    };
  };

  config = {
    # Wayland user-specific configuration
    # System-level Wayland config is in modules/sway.nix

    # Wayland user packages
    home.packages =
      with pkgs;
      [
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
        gruvbox-dark-gtk
        gruvbox-dark-icons-gtk
        adwaita-qt
        wayvnc
        sway-audio-idle-inhibit
        polkit_gnome
        amdgpu_top
        python3
        sound-theme-freedesktop
      ]
      ++ [
        # Waybar custom module scripts
        (pkgs.writeShellScriptBin "waybar-amdgpu" (
          builtins.readFile ../../config/waybar/scripts/waybar-amdgpu.sh
        ))

        (pkgs.writeShellScriptBin "waybar-nvidiagpu" (
          builtins.readFile ../../config/waybar/scripts/waybar-nvidiagpu.sh
        ))

        (pkgs.writeShellScriptBin "waybar-swaync" (
          builtins.readFile ../../config/waybar/scripts/waybar-swaync.sh
        ))

        (pkgs.writeShellScriptBin "waybar-weather" (
          builtins.readFile ../../config/waybar/scripts/waybar-weather.sh
        ))

        (pkgs.writeShellScriptBin "waybar-powerprofile" (
          builtins.readFile ../../config/waybar/scripts/waybar-powerprofile.sh
        ))

        (pkgs.writeShellScriptBin "waybar-powerprofile-cycle" (
          builtins.readFile ../../config/waybar/scripts/waybar-powerprofile-cycle.sh
        ))

        (pkgs.writeShellScriptBin "claude-focus" (
          builtins.readFile ../../config/claude/hooks/claude-focus.sh
        ))

        (pkgs.writeShellScriptBin "claude-popup" (
          builtins.readFile ../../config/claude/hooks/claude-popup.sh
        ))
      ];

    # HiDPI cursor (Capitaine Gruvbox at 1.5x = 36)
    home.pointerCursor = {
      name = "Capitaine Cursors (Gruvbox)";
      package = pkgs.capitaine-cursors-themed;
      size = 36;
      gtk.enable = true;
      x11.enable = true;
    };

    # Wayland session variables
    home.sessionVariables = {
      GTK_THEME = "Gruvbox-Dark";
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
      WAYBAR_WEATHER_LAT = location.lat;
      WAYBAR_WEATHER_LON = location.lon;
    };

    # Night light (color temperature adjustment)
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = location.latFloat;
      longitude = location.lonFloat;
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
    xdg.configFile."sway/common".source = ../../config/sway/common;
    xdg.configFile."sway/wallpaper.jpg".source = ../../config/sway/wallpaper.jpg;

    # Waybar configuration
    xdg.configFile."waybar/config".text = builtins.toJSON (
      lib.recursiveUpdate config.custom.waybar.base config.custom.waybar.hostOverrides
    );
    xdg.configFile."waybar/style.css".source = ../../config/waybar/style.css;

    # Wofi launcher configuration
    xdg.configFile."wofi/style.css".source = ../../config/wofi/style.css;
    xdg.configFile."wofi/config".source = ../../config/wofi/config;

    # SwayNC notification daemon configuration
    xdg.configFile."swaync/config.json".source = ../../config/swaync/config.json;

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
      setSessionVariables = true;
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
  };
}

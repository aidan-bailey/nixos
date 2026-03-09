# Module Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split Claude Code ecosystem out of devtools.nix into a dedicated module, and consolidate Waybar configs from raw JSON into Nix attrsets with a shared base and per-host deltas.

**Architecture:** Two independent refactors. Task 1 extracts `home/modules/claude.nix` from `home/modules/devtools.nix` and registers it as a peer module. Task 2 replaces three raw JSON Waybar configs with Nix-generated JSON using custom home-manager options for base + override merging via `lib.recursiveUpdate`.

**Tech Stack:** NixOS, home-manager, Nix module system

**Verification:** Since this is a NixOS config (no unit tests), every task is verified by running `nixos-rebuild build --flake .#nesco` and `nixos-rebuild build --flake .#fresco`. Both must succeed. medesco is server-only (no home-manager desktop modules) so it's unaffected.

---

### Task 1: Create `home/modules/claude.nix` and trim `devtools.nix`

These must happen atomically — creating claude.nix without trimming devtools.nix would cause duplicate option declarations (sops.secrets, programs.zsh.profileExtra) that fail the build.

**Files:**
- Create: `home/modules/claude.nix`
- Modify: `home/modules/devtools.nix`
- Modify: `home/users/aidanb/default.nix`

**Step 1: Create `home/modules/claude.nix`**

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

let
  claude-squad = pkgs.buildGoModule rec {
    pname = "claude-squad";
    version = "1.0.16";
    src = pkgs.fetchFromGitHub {
      owner = "smtg-ai";
      repo = "claude-squad";
      rev = "v${version}";
      hash = "sha256-ecR+CqCO6uoWd6yVN3QpZAnA/xWZIOAHvwjbJgAQwNo=";
    };
    vendorHash = "sha256-Rc0pIwnA0k99IKTvYkHV54RxtY87zY1TmmmMl+hYk6Q=";
    env.CGO_ENABLED = 0;
    doCheck = false;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      mv $out/bin/claude-squad $out/bin/cs
      wrapProgram $out/bin/cs --prefix PATH : ${lib.makeBinPath [ pkgs.tmux pkgs.gh pkgs.git ]}
    '';
  };

  tail-claude = pkgs.buildGoModule rec {
    pname = "tail-claude";
    version = "0.3.5";
    src = pkgs.fetchFromGitHub {
      owner = "kylesnowschwartz";
      repo = "tail-claude";
      rev = "v${version}";
      hash = "sha256-bKmcdjO1vWumgW5zqJf3wUPI3XPgqSof3PtI98NY/Oc=";
    };
    vendorHash = "sha256-BE+tZvkjR36cN0SGjUZNylU2J58FVUZfpFw3+2ObfNc=";
    env.CGO_ENABLED = 0;
  };
in
{
  home.packages = [
    inputs.claude-code-nix.packages.${system}.default
    jq
    bun
    claude-squad
    tail-claude
    (pkgs.mcp-nixos.overridePythonAttrs { doCheck = false; })
  ];

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
  ];

  home.file.".claude/hooks/notify.sh" = {
    source = ../../config/claude/hooks/notify.sh;
    executable = true;
  };

  sops.secrets.claude_code_oauth_token = { };
  programs.zsh.profileExtra = ''
    export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${config.sops.secrets.claude_code_oauth_token.path})"
  '';
}
```

Note: `jq` and `bun` need `pkgs.` prefix since there's no `with pkgs` — fix in the packages list:
```nix
  home.packages = [
    inputs.claude-code-nix.packages.${system}.default
    pkgs.jq
    pkgs.bun
    claude-squad
    tail-claude
    (pkgs.mcp-nixos.overridePythonAttrs { doCheck = false; })
  ];
```

**Step 2: Trim `devtools.nix`**

Remove these sections from `home/modules/devtools.nix`:

- Lines 11-41: Remove the `claude-squad` and `tail-claude` let bindings entirely. Keep the `let` keyword and the `devlibs` list.
- Lines 113-119: Remove the "Claude Code ecosystem" block from the `devlibs` list (tmux stays — it's line 114 with comment "claude-squad session management" but per design tmux stays in devtools).

Wait — tmux stays in devtools. So remove from the devlibs list: `jq`, `bun`, `claude-squad`, `tail-claude`, `mcp-nixos` (lines 115-119). Keep `tmux` (line 114).

- Lines 123-126: Change `home.packages` to just `devlibs` (remove `inputs.claude-code-nix` line):
  ```nix
  home.packages = devlibs;
  ```

- Line 132: Remove `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true";` from `home.sessionVariables`. Keep `LD` and `RUSTC_WRAPPER`.

- Lines 135-137: Remove the entire `home.sessionPath` block.

- Lines 147-150: Remove the `home.file.".claude/hooks/notify.sh"` block.

- Lines 152-156: Remove the SOPS secret and zsh profileExtra blocks.

The resulting `devtools.nix` should look like:

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:

let
  devlibs = with pkgs; [
    # Essentials
    ffmpeg
    libtool
    cmake
    clang
    llvm
    curl
    gh
    pkg-config
    gnumake
    mold

    # Shell
    shfmt
    shellcheck
    nodePackages.bash-language-server
    nodePackages.pnpm

    # Markdown
    uv
    pandoc
    marksman

    # Nix
    nixd
    nixfmt

    # Antigravity
    inputs.antigravity-nix.packages.${system}.default
    (inputs.harbour.lib.mkHarbour {
      inherit pkgs;
      buildOpts = {
        enableFreeImage = false;
        enableCurl = true;
        enableOpenSSL = true;
      };
    })
    # JS
    nodejs_22

    # DB
    postgresql
    dbeaver-bin
    # Emulation
    qemu
    libvirt
    swtpm
    guestfs-tools
    libosinfo
    virtiofsd
    # Python
    python3
    pyright
    pyenv
    semgrep
    pipenv
    # XML
    libxslt
    # Rust
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [ "clippy" "rustfmt" "rust-analyzer" "rust-src" ];
    })
    cargo-audit
    cargo-machete
    sccache # Rust compilation caching
    lldb
    autoconf
    automake

    tmux
  ];
in
{
  home.packages = devlibs;

  # Session variables
  home.sessionVariables = {
    LD = "mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    baseIndex = 1;
  };
}
```

**Step 3: Add `claude.nix` to imports in `home/users/aidanb/default.nix`**

Add `../../modules/claude.nix` to the imports list (after devtools.nix, line 15):

```nix
  imports = [
    ../../modules/shell.nix
    ../../modules/terminal.nix
    ../../modules/editor.nix
    ../../modules/git.nix
    ../../modules/ssh.nix
    ../../modules/development.nix
    ../../modules/devtools.nix
    ../../modules/claude.nix
    ../../modules/zed.nix
    ../../modules/secrets.nix
    ../../modules/gpg.nix
  ];
```

**Step 4: Build to verify**

```bash
nixos-rebuild build --flake .#nesco 2>&1
nixos-rebuild build --flake .#fresco 2>&1
```

Expected: Both succeed with no errors.

**Step 5: Commit**

```bash
git add home/modules/claude.nix home/modules/devtools.nix home/users/aidanb/default.nix
git commit -m "refactor(home): extract Claude Code ecosystem into claude.nix"
```

---

### Task 2: Define Waybar base config and options in `wayland.nix`

**Files:**
- Modify: `home/modules/wayland.nix`

**Step 1: Add `waybarBase` to the let block and define options + config**

Replace the module structure from a plain config module to one with `options` and `config` sections. Add `lib` to the function args (already present).

The new `wayland.nix` structure:

```nix
{ config, pkgs, lib, ... }:

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
    modules-left = [ "sway/workspaces" "sway/mode" "sway/scratchpad" ];
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
      format-icons = [ "" "" ];
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
      consume-icons = { on = "󰆤 "; };
      random-icons = { on = "󰒟 "; };
      repeat-icons = { on = "󰑖 "; };
      single-icons = { on = "󰑘 "; };
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
        default = [ "󰕾" "󰕿" "󰖀" ];
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
      description = "Shared Waybar base config. Read-only; use hostOverrides to customize.";
    };

    hostOverrides = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Per-host Waybar overrides, deep-merged onto the base config.";
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
        gnome-themes-extra
        adwaita-icon-theme
        adwaita-qt
        wayvnc
        sway-audio-idle-inhibit
        polkit_gnome
        amdgpu_top
        python3
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

    # Waybar configuration — generated from base + hostOverrides
    xdg.configFile."waybar/config".text = builtins.toJSON
      (lib.recursiveUpdate config.custom.waybar.base config.custom.waybar.hostOverrides);
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
  };
}
```

Key changes from the original `wayland.nix`:
- Added `waybarBase` attrset to the `let` block (shared Waybar config as Nix)
- Added `options.custom.waybar.base` (readOnly) and `options.custom.waybar.hostOverrides`
- Wrapped existing config in a `config = { ... }` block (required when using `options`)
- Replaced `xdg.configFile."waybar/config".source = ...` with `.text = builtins.toJSON (lib.recursiveUpdate ...)`
- Removed old `xdg.configFile."waybar/config".source` line

**Step 2: Build to verify (will fail until per-host files are updated in Task 3, so proceed to Task 3 before building)**

---

### Task 3: Update per-host files to set Waybar overrides

**Files:**
- Modify: `home/hosts/nesco.nix`
- Modify: `home/hosts/fresco.nix`

**Step 1: Rewrite `home/hosts/nesco.nix`**

```nix
{ ... }:
{
  imports = [ ../profiles/desktop.nix ];
  xdg.configFile."sway/config".source = ../../config/sway/nesco/config;

  custom.waybar.hostOverrides = {
    margin-bottom = 8;
    margin-left = 12;
    margin-right = 12;
    modules-right = [
      "custom/swaync" "mpd" "pulseaudio"
      "network" "backlight" "battery"
      "custom/powerprofile" "custom/gpu"
      "cpu" "memory" "temperature"
      "idle_inhibitor" "tray"
      "custom/weather" "clock"
    ];

    temperature.critical-threshold = 85;

    backlight = {
      format = "{icon} {percent}%";
      format-icons = [ "󰃞" "󰃞" "󰃞" "󰃟" "󰃟" "󰃟" "󰃠" "󰃠" "󰃠" ];
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
      format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
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
      format-icons = [ "󱐋" "󱐋" "󱐋" "󱐋" "󱐋" ];
      tooltip = true;
      on-click = "alacritty -e btop";
    };
  };
}
```

Note: `lib` is no longer needed in the args since `lib.mkForce` is removed.

**Step 2: Rewrite `home/hosts/fresco.nix`**

```nix
{ ... }:
{
  imports = [ ../profiles/desktop.nix ];
  xdg.configFile."sway/config".source = ../../config/sway/fresco/config;

  custom.waybar.hostOverrides = {
    margin-bottom = 4;
    margin-left = 6;
    margin-right = 6;
    modules-right = [
      "custom/swaync" "mpd" "pulseaudio"
      "network" "disk" "custom/gpu"
      "cpu" "memory" "temperature"
      "idle_inhibitor" "tray"
      "custom/weather" "clock"
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
      format-icons = [ "󰊴" "󰊴" "󰊴" "󰊴" "󰊴" ];
      tooltip = true;
      on-click = "alacritty -e btop";
    };
  };
}
```

**Step 3: Build to verify**

```bash
nixos-rebuild build --flake .#nesco 2>&1
nixos-rebuild build --flake .#fresco 2>&1
```

Expected: Both succeed. The generated `~/.config/waybar/config` should be JSON equivalent to the old per-host JSON files.

**Step 4: Commit**

```bash
git add home/modules/wayland.nix home/hosts/nesco.nix home/hosts/fresco.nix
git commit -m "refactor(waybar): consolidate configs into Nix base + per-host deltas"
```

---

### Task 4: Delete old Waybar JSON config files

**Files:**
- Delete: `config/waybar/config`
- Delete: `config/waybar/nesco/config`
- Delete: `config/waybar/fresco/config`
- Delete: `config/waybar/nesco/` (empty directory)
- Delete: `config/waybar/fresco/` (empty directory)

**Step 1: Remove files and directories**

```bash
git rm config/waybar/config
git rm config/waybar/nesco/config
git rm config/waybar/fresco/config
```

The directories `config/waybar/nesco/` and `config/waybar/fresco/` will be removed automatically by git when empty.

**Step 2: Build to verify (sanity check — nothing references these files anymore)**

```bash
nixos-rebuild build --flake .#nesco 2>&1
nixos-rebuild build --flake .#fresco 2>&1
```

Expected: Both succeed (no Nix expressions reference these deleted files).

**Step 3: Commit**

```bash
git commit -m "chore: remove old Waybar JSON configs (now Nix-generated)"
```

---

### Verification checklist

After all tasks, confirm:
- [ ] `nixos-rebuild build --flake .#nesco` succeeds
- [ ] `nixos-rebuild build --flake .#fresco` succeeds
- [ ] `home/modules/claude.nix` exists and is imported
- [ ] `home/modules/devtools.nix` has no Claude-related code
- [ ] `config/waybar/config`, `config/waybar/nesco/config`, `config/waybar/fresco/config` are deleted
- [ ] `config/waybar/style.css` and `config/waybar/scripts/*.sh` are untouched

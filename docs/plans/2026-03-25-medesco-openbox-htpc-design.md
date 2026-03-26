# Medesco Openbox HTPC Design

## Context

Medesco is a media server connected to a TV, primarily used as a fullscreen Jellyfin kiosk with occasional light desktop use (browser for managing *arr services, terminal, light gaming). It currently uses `serverModules` which has no graphical session. The user wants a "conventional" (stacking/floating) window manager rather than Sway.

**Decision**: Openbox on X11 — the classic HTPC window manager. Ultra-lightweight, battle-tested for TV setups, stacking/floating paradigm.

## Architecture

### New profile: `htpcModules`

Defined in `flake.nix`, extends `serverModules`:

```nix
htpcModules = serverModules ++ [
  ./modules/openbox.nix
  ./modules/audio.nix
  ./modules/gaming.nix
  ./modules/nix-ld.nix
];
```

Medesco switches from `profile = serverModules` to `profile = htpcModules`.

### New files

| File | Purpose |
|------|---------|
| `modules/openbox.nix` | System-level X11 + Openbox + fonts + desktop plumbing |
| `home/hosts/medesco.nix` | Home-manager: Openbox config, autostart, packages |
| `config/openbox/rc.xml` | Openbox keybindings and window behavior |
| `config/openbox/menu.xml` | Right-click desktop menu |
| `config/openbox/autostart` | Startup script (picom, Jellyfin, tint2) |

### Modified files

| File | Change |
|------|--------|
| `flake.nix` | Add `htpcModules`, switch medesco to use it |
| `hosts/medesco/configuration.nix` | Add display type, home-manager host import |

## System module: `modules/openbox.nix`

### X11 and Openbox

- `services.xserver.enable = true`
- `services.xserver.displayManager.startx.enable = true` (no display manager)
- `services.xserver.windowManager.openbox.enable = true`
- Auto-login via `loginShellInit`: runs `startx` on tty1 (mirrors existing Sway pattern)

### Fonts

Same set as `sway.nix`:

- `nerd-fonts.noto`, `noto-fonts`, `noto-fonts-color-emoji`
- Font rendering conditioned on `custom.display.type` (antialias, hinting, subpixel)

### Desktop plumbing

- `security.polkit.enable = true`
- `services.dbus.enable = true`
- `programs.dconf.enable = true`
- `services.gnome.gnome-keyring.enable = true`
- Keyboard layout: `za`, caps:swapescape, `console.useXkbConfig = true`

### Packages

- `libsecret` (keyring integration)
- `picom` (compositor for tear-free video on TV)

### Not included (vs sway.nix)

- No XDG Wayland portals (X11 apps don't need them)
- No PipeWire config (stays in `audio.nix`)
- No Wayland-specific env vars

## Home-manager: `home/hosts/medesco.nix`

### Imports

- `home/modules/apps.nix` — Firefox for *arr management UIs
- `home/modules/gaming.nix` — Steam, Proton, gaming packages

### Openbox config files (via `xdg.configFile`)

- `openbox/rc.xml` — sourced from `config/openbox/rc.xml`
- `openbox/menu.xml` — sourced from `config/openbox/menu.xml`
- `openbox/autostart` — sourced from `config/openbox/autostart`

### Autostart sequence

1. `picom --backend glx &` — compositor for tear-free playback
2. `feh --bg-fill <wallpaper>` — wallpaper
3. `tint2 &` — lightweight panel
4. `jellyfin-media-player --fullscreen &` — primary kiosk app

### Right-click menu entries

- Jellyfin Media Player
- Firefox
- Alacritty (terminal)
- Transmission Qt
- Separator
- Reconfigure Openbox
- Exit

### Keybindings (rc.xml)

- `Super+Return` — Alacritty
- `Super+d` — rofi (app launcher)
- `Super+f` — toggle fullscreen
- `Super+q` — close window
- `Alt+Tab` — cycle windows
- `Super+j` — Jellyfin Media Player

### Packages

- `tint2` — lightweight panel (taskbar, tray, clock)
- `feh` — wallpaper setter
- `rofi` — app launcher
- `xclip` — clipboard
- `xdotool` — window manipulation scripting

### Theming

- `GTK_THEME = "Gruvbox-Dark"` (consistent with nesco/fresco)
- Capitaine Cursors (Gruvbox) pointer cursor
- Gruvbox Dark GTK + icons packages

### Not included (vs desktop profile)

- No waybar, swaybg, swaylock, wofi, kanshi, wl-clipboard
- No gammastep (night light)
- No wayland session variables
- No Sway config files
- No helix, research home modules

## Host config: `hosts/medesco/configuration.nix`

```nix
{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  custom.hostType = "server";
  custom.display.type = "lcd"; # TV panel

  networking.hostName = "medesco";

  home-manager.users.aidanb.imports = [
    ../../home/hosts/medesco.nix
  ];
}
```

Note: `custom.hostType` stays `"server"` — no TLP/power management needed for an always-on HTPC. The display type is set to `"lcd"` for correct font rendering on a TV.

## Dependency notes

- `modules/audio.nix` already exists and needs no changes — provides PipeWire with Bluetooth codecs
- `modules/gaming.nix` already exists — gated by `custom.features.gaming` (defaults true)
- `modules/nix-ld.nix` already exists — needed for Steam/Proton FHS compatibility
- `hardware-configuration.nix` is still a placeholder — must be regenerated on target hardware before deployment
- `.sops.yaml` still has no medesco age key — secrets setup is a separate task

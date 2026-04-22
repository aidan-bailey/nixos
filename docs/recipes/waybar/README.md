# Waybar

## Overview

Read this when modifying the status bar. Waybar config is Nix-generated from a shared base merged with per-host overrides.

## Design

### Generation Pattern

1. `home/modules/wayland.nix` defines a `waybarBase` attrset (~180 lines) with 15 shared modules
2. Two custom options expose this:
   - `custom.waybar.base` — read-only, contains `waybarBase`
   - `custom.waybar.hostOverrides` — customizable, default `{}`
3. Per-host files (`home/hosts/nesco.nix`, `home/hosts/fresco.nix`) set `custom.waybar.hostOverrides`
4. The final config is generated: `lib.recursiveUpdate base hostOverrides` → `builtins.toJSON` → written to `~/.config/waybar/config`

### Module Types

**Built-in Waybar modules** — configured directly in the attrset (e.g., `clock`, `cpu`, `memory`, `network`, `pulseaudio`)

**Custom modules** — use shell scripts via `pkgs.writeShellScriptBin`:
```nix
pkgs.writeShellScriptBin "waybar-weather" (builtins.readFile ../../config/waybar/scripts/weather.sh)
```

Custom modules reference their scripts via `exec` in the Waybar config:
```nix
"custom/weather" = {
  exec = "waybar-weather";
  return-type = "json";
  interval = 900;
};
```

### Styling

`config/waybar/style.css` is shared across all hosts, deployed via `xdg.configFile`.

## Key Files

| File | Role |
|------|------|
| `home/modules/wayland.nix` | `waybarBase` definition, custom options, script wrappers |
| `home/hosts/nesco.nix` | nesco Waybar overrides (battery, backlight, AMDGPU) |
| `home/hosts/fresco.nix` | fresco Waybar overrides (disk, NVIDIA GPU) |
| `config/waybar/style.css` | Shared styling |
| `config/waybar/scripts/*.sh` | Shell scripts for custom modules |

## Recipes

- [Add a shared module](add-shared-module.md) — Add a Waybar module to the shared base
- [Add a host override](add-host-override.md) — Add a host-specific Waybar module or override
- [Add a custom script](add-custom-script.md) — Add a shell-script-based custom module

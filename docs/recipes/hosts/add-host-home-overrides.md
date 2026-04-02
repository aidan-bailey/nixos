# Add Host Home Overrides

## When to use

When a desktop host needs user-level customizations — Sway config source, Waybar overrides, or host-specific program settings.

## Files to modify

1. **Create** `home/hosts/<name>.nix` — per-host home-manager overrides
2. **Modify** `hosts/<name>/configuration.nix` — add the import line

## Steps

### 1. Create the per-host home file

```nix
{ config, pkgs, lib, ... }:
{
  imports = [ ../profiles/desktop.nix ];

  # Sway config from host-specific directory
  xdg.configFile."sway/config".source = ../../config/sway/<name>/config;

  # Waybar host overrides (merged with base via lib.recursiveUpdate)
  custom.waybar.hostOverrides = {
    # Override modules-right for this host's hardware
    modules-right = [
      "tray"
      "cpu"
      "memory"
      "temperature"
      "network"
      "pulseaudio"
      "custom/swaync"
      "clock"
    ];

    # Host-specific modules
    temperature.critical-threshold = 85;
  };
}
```

### 2. Add import in host configuration.nix

```nix
home-manager.users.aidanb.imports = [ ../../home/hosts/<name>.nix ];
```

### 3. Create host Sway config directory

```bash
mkdir -p config/sway/<name>/
cp config/sway/nesco/config config/sway/<name>/config    # start from existing
```

Edit the Sway config for the host's display setup (output names, resolution, scaling).

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- The per-host home file MUST import a profile (e.g., `../profiles/desktop.nix`) — this is how desktop modules get included
- Waybar overrides use `lib.recursiveUpdate` — you only need to specify what differs from `waybarBase` in `home/modules/wayland.nix`
- Sway config files live in `config/sway/<host>/config` — these are static files, not Nix-generated
- Server hosts (medesco) don't have per-host home files because they don't use desktop profiles

# Hosts

## Overview

Read this when adding a new host machine or modifying host-specific configuration. Each host is defined by a NixOS configuration, optional device module, and optional home-manager overrides.

## Design

### mkHost Helper

Hosts are created via the `mkHost` function in `flake.nix`:

```nix
mkHost = { hostConfig, profile }:
  nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [ hostConfig ] ++ profile ++ commonModules;
    specialArgs = { inherit inputs system; };
  };
```

Module priority: `hostConfig` > `profile` > `commonModules` (leftmost wins for conflicting options).

### Per-Host Integration Pattern

Each host's `configuration.nix` does three things:
1. Imports `hardware-configuration.nix` (generated per machine via `nixos-generate-config`)
2. Imports its device module (e.g., `modules/devices/zenbook_s16.nix`)
3. Injects per-host home-manager overrides via `home-manager.users.aidanb.imports`

### Current Hosts

| Host | Profile | Device Module | Type |
|------|---------|--------------|------|
| nesco | desktopModules | `devices/zenbook_s16.nix` | laptop (Zen 5, AMD iGPU) |
| fresco | desktopModules | `devices/fresco.nix` | desktop (Zen 4, NVIDIA) |
| medesco | serverModules | none | server (headless) |

## Key Files

| File | Role |
|------|------|
| `flake.nix` | `mkHost`, profile definitions, `nixosConfigurations` output |
| `hosts/<name>/configuration.nix` | Host entry point |
| `hosts/<name>/hardware-configuration.nix` | Generated hardware config |
| `home/hosts/<name>.nix` | Per-host home-manager overrides |

## Recipes

- [Add a host](add-host.md) — Add a new machine to the flake
- [Modify host config](modify-host-config.md) — Change host-specific settings
- [Add host home overrides](add-host-home-overrides.md) — Add per-host user environment customizations

# Modules

## Overview

Read this when adding or modifying NixOS system modules or home-manager modules. This repo uses a two-layer module system with custom options for conditional behavior.

## Design

### Two-Layer System

**System modules** (`modules/`) configure NixOS options — hardware, services, kernel, system packages. They receive `inputs` and `system` via `specialArgs` in `flake.nix`.

**Home-manager modules** (`home/modules/`) configure the user environment — programs, dotfiles, shell, editor. They receive `inputs` and `system` via `extraSpecialArgs`. All home modules are imported from `home/users/aidanb/default.nix`.

### Module Composition

Modules are composed into profiles in `flake.nix`:

- **serverModules** — `base.nix`, `user.nix`, `networking.nix`, `terminal.nix`, `mediaserver.nix`, `secrets.nix`, `benchmarking.nix`
- **desktopModules** — serverModules + `kernel/cachyos.nix`, `sway.nix`, `audio.nix`, `bluetooth.nix`, `gaming.nix`, `nix-ld.nix`, `virtualisation.nix`, `power.nix`, plus doom-flake

### Module Conventions

- Use `let` blocks to organize package lists before assigning them to `environment.systemPackages` or `home.packages`
- System modules use `{ config, pkgs, lib, inputs, system, ... }:` as their function signature
- Home modules use `{ config, pkgs, lib, inputs, system, ... }:` via `extraSpecialArgs`
- Conditional behavior uses custom options from `modules/profile.nix` (e.g., `lib.mkIf config.custom.features.gaming`)
- Use `lib.mkDefault` for values that hosts/devices should be able to override
- Use `lib.mkForce` to override inherited defaults

### Custom Options

Four options defined in `modules/profile.nix` control conditional behavior:

| Option | Type | Values | Controls |
|--------|------|--------|----------|
| `custom.hostType` | enum | `"laptop"`, `"desktop"`, `"server"` | TLP, sleep, power |
| `custom.display.type` | nullable enum | `"oled"`, `"lcd"`, `null` | Font rendering, subpixel |
| `custom.features.gaming` | bool | default `true` | Steam, Proton |
| `custom.features.virtualisation` | bool | default `true` | Docker, libvirt, KVM |

These are set in device modules or host configs and consumed by `sway.nix`, `power.nix`, `gaming.nix`, `virtualisation.nix`, etc.

## Key Files

| File | Role |
|------|------|
| `flake.nix` | Defines `serverModules`, `desktopModules`, `commonModules`, `mkHost` |
| `modules/profile.nix` | Custom option definitions |
| `modules/*.nix` | System modules |
| `home/modules/*.nix` | Home-manager modules |
| `home/users/aidanb/default.nix` | Home module import list (base modules) |
| `home/profiles/desktop.nix` | Desktop profile (imports wayland, gaming, apps, research, helix) |

## Recipes

- [Add a system module](add-system-module.md) — Add a new NixOS system-level module
- [Add a home-manager module](add-home-module.md) — Add a new user-level module
- [Add a custom option](add-custom-option.md) — Add a new conditional option to `profile.nix`
- [Add a home profile](add-home-profile.md) — Create a new home-manager profile

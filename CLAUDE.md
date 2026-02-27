# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A flake-based NixOS configuration for three hosts (nesco, fresco, medesco) targeting AMD Zen 5 hardware. Uses nixos-unstable, CachyOS kernel, home-manager, and Wayland/Sway.

## Common Commands

```bash
# Rebuild and switch to new configuration (run from repo root)
sudo nixos-rebuild switch --flake .#nesco
sudo nixos-rebuild switch --flake .#fresco
sudo nixos-rebuild switch --flake .#medesco

# Test a configuration without switching (dry activation)
sudo nixos-rebuild test --flake .#nesco

# Build without activating
nixos-rebuild build --flake .#nesco

# Update flake inputs
nix flake update

# Update a single input
nix flake update nixpkgs

# Check flake validity
nix flake check

# Format nix files
nixfmt .
```

## Architecture

### Host / Module Split

The flake defines a `mkHost` helper that combines a host-specific config with `commonModules` (chaotic, doom-flake, nixarr, home-manager). Each host imports only the system modules it needs:

- **nesco** — Full desktop: Sway, gaming, audio, bluetooth, virtualisation, power, mediaserver, Zenbook S16 device module
- **fresco** — Same as nesco without device-specific module
- **medesco** — Minimal server: base, user, networking, terminal, mediaserver only

### Two-Layer Module System

**System modules** (`modules/`) configure NixOS options — hardware, services, kernel, system packages. They receive `inputs` and `system` via `specialArgs`.

**Home-manager modules** (`home/modules/`) configure user environment — programs, dotfiles, shell, editor. They receive `inputs` and `system` via `extraSpecialArgs`. All home modules are imported from `home/users/aidanb/default.nix`.

### Key Modules

- `modules/amd/zen5.nix` — Imports cpu.nix, sets `-march=znver5` compiler flags globally and patches the kernel for znver5
- `modules/devices/zenbook_s16.nix` — Imports AMD graphics+CPU modules, adds device-specific kernel params and power behavior
- `modules/sway.nix` — Enables Sway at system level with PipeWire, XDG portals, GNOME keyring, fonts; auto-starts Sway on tty1
- `home/modules/wayland.nix` — User-side Sway config, Waybar, and Wayland tools; sources config files from `config/sway/` and `config/waybar/`
- `home/modules/devtools.nix` — Development tools and Zed editor configuration with hardcoded LSP paths (nixd, pyright, ruff, rust-analyzer)

### Config Files

Static configuration files for Sway and Waybar live in `config/sway/` and `config/waybar/`. They are referenced by home-manager via `home.file` in `home/modules/wayland.nix`.

### Flake Inputs of Note

- **chaotic** (CachyOS/nyx) — Provides optimized CachyOS kernel
- **doom-flake** (local, `flakes/doom-emacs/`) — Doom Emacs with PGTK + native-comp
- **nixarr** — Media server stack (Jellyfin, Sonarr, Radarr, etc.)
- **antigravity-nix**, **harbour** — Compilation optimization tools, exposed as packages in devtools

### Patterns

- Modules use `let` blocks to organize package lists before assigning them
- `lib.mkForce` is used to explicitly disable unwanted services (picom, xrdp, xen)
- Package overrides are done inline with `overrideAttrs` (see Cockatrice in `home/modules/gaming.nix`, Xen in `modules/virtualisation.nix`)
- The user is `aidanb` with groups: wheel, docker, libvirtd, networkmanager

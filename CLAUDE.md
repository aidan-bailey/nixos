# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A flake-based NixOS configuration for three hosts (nesco, fresco, medesco) on AMD hardware (Zen 4 and Zen 5). Uses nixos-unstable, CachyOS kernel, home-manager, sops-nix, and Wayland/Sway.

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

The flake defines a `mkHost` helper that combines a host-specific config with `commonModules` (chaotic, doom-flake, nixarr, home-manager, sops-nix). Module composition is done via two profiles defined in `flake.nix`:

- **serverModules** — base, user, networking, terminal, mediaserver, secrets
- **desktopModules** — serverModules + cachyos kernel, sway, audio, bluetooth, gaming, nix-ld, virtualisation, power

Each host selects a profile and a device module:

- **nesco** — desktopModules + `devices/zenbook_s16.nix` (AMD iGPU, asusd, HDR)
- **fresco** — desktopModules + `devices/fresco.nix` (Zen 4 + NVIDIA, performance tuning)
- **medesco** — serverModules only (no device module)

### Two-Layer Module System

**System modules** (`modules/`) configure NixOS options — hardware, services, kernel, system packages. They receive `inputs` and `system` via `specialArgs`.

**Home-manager modules** (`home/modules/`) configure user environment — programs, dotfiles, shell, editor. They receive `inputs` and `system` via `extraSpecialArgs`. All home modules are imported from `home/users/aidanb/default.nix`.

### CPU / GPU Module Hierarchy

CPU and GPU support is layered — device modules pick the pieces they need:

- `modules/amd/cpu.nix` — AMD microcode, `amd_pstate=active`, firmware (shared base)
- `modules/amd/zen4.nix` — Imports cpu.nix, sets `hostPlatform.gcc.arch/tune = "znver4"`, kernel KCFLAGS, RUSTFLAGS, GOAMD64
- `modules/amd/zen5.nix` — Same pattern for znver5
- `modules/amd/graphics.nix` — AMDGPU driver, Mesa, VA-API (used by zenbook_s16)
- `modules/nvidia/gpu.nix` — NVIDIA open driver, VA-API/VDPAU, container toolkit, persistenced, shader cache, PAT (used by fresco)

Device modules compose these: `zenbook_s16.nix` imports `amd/graphics.nix` + `amd/cpu.nix`; `fresco.nix` imports `nvidia/gpu.nix` + `amd/zen4.nix`.

### Key Modules

- `modules/base.nix` — Core system packages, zram swap (zstd, 50%), tmpfs /tmp, CUPS printing
- `modules/networking.nix` — NetworkManager, encrypted DNS-over-TLS (1.1.1.1, 9.9.9.9), mDNS via Avahi, nftables firewall, SSH
- `modules/audio.nix` — PipeWire with Bluetooth codec support (SBC-XQ, LDAC, aptX, aptX-HD)
- `modules/sway.nix` — Enables Sway at system level with XDG portals, GNOME keyring, fonts (Nerd Fonts), OLED font rendering; auto-starts Sway on tty1
- `modules/kernel/cachyos.nix` — Sets `boot.kernelPackages = pkgs.linuxPackages_cachyos`
- `modules/secrets.nix` — SOPS-nix with age encryption for system-level secrets
- `modules/devices/zenbook_s16.nix` — AMD iGPU, HDR, asusd fan control, PSR disable, RCU tuning, resume device
- `modules/devices/fresco.nix` — Zen 4 + NVIDIA, performance governor, EPP, sched-ext scx_lavd, TCP BBR, NVMe/EXT4 tuning, earlyoom, irqbalance, WiFi ASPM workaround
- `home/modules/wayland.nix` — User-side Sway config, Waybar, Wayland tools, Gammastep night light, HiDPI cursor, polkit agent; sources config files from `config/sway/` and `config/waybar/`
- `home/modules/devtools.nix` — Dev tools, Zed editor with vim mode and LSP configs (nixd, pyright, ruff, rust-analyzer), sccache, mold linker
- `home/modules/secrets.nix` — SOPS-nix home-manager module for user secrets

### Per-Host Sway Config

Each desktop host has its own Sway config file: `config/sway/{host}/config`. These are linked by per-host home-manager files in `home/hosts/{host}.nix`, which are imported in each host's `configuration.nix`.

### Secrets

Encrypted secrets are managed by sops-nix with age encryption. Secrets live in `secrets/` (secrets.yaml for system, home.yaml for user). Key configuration is in `.sops.yaml`. The system keyfile is at `/var/lib/sops-nix/key.txt`, the user keyfile at `~/.config/sops/age/keys.txt`.

### Flake Inputs of Note

- **chaotic** (CachyOS/nyx) — Provides optimized CachyOS kernel and overlays
- **doom-flake** (local, `flakes/doom-emacs/`) — Doom Emacs with PGTK + native-comp
- **nixarr** — Media server stack (Jellyfin, Sonarr, Radarr, etc.)
- **sops-nix** — Encrypted secrets management
- **antigravity-nix**, **harbour** — Compilation optimization tools, exposed as packages in devtools

### Patterns

- Modules use `let` blocks to organize package lists before assigning them
- `lib.mkForce` is used to override inherited defaults (e.g. fresco disables TLP, overrides OLED font rendering to LCD)
- Package overrides are done inline with `overrideAttrs` (see Cockatrice in `home/modules/gaming.nix`, Xen in `modules/virtualisation.nix`)
- Module composition profiles (serverModules, desktopModules) are defined in `flake.nix` and shared across hosts
- The user is `aidanb` with groups: wheel, docker, libvirtd, networkmanager, video

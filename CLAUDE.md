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

# Edit encrypted secrets
sops secrets/secrets.yaml   # system secrets
sops secrets/home.yaml      # user secrets
```

Shell aliases defined in `home/modules/shell.nix`:
- `updaten` — `nix flake update` piped through `nom` (pretty nix output)
- `configure` — `nvim /etc/nixos/configuration.nix`
- `nix-sync-cache` — sync nix store to local binary cache at `/mnt/nixos-cache`
- `cs` — `claude-squad` (multi-session manager)
- `tc` — `tail-claude` (session log viewer)
- `rt` — `ralph-tui` (autonomous loop orchestrator)

## Architecture

### Host / Module Split

The flake defines a `mkHost` helper that combines a host-specific config with `commonModules` (doom-flake, nixarr, home-manager, sops-nix). Module composition is done via two profiles defined in `flake.nix`:

- **serverModules** — base, user, networking, terminal, mediaserver, secrets, benchmarking
- **desktopModules** — serverModules + cachyos kernel, sway, audio, bluetooth, gaming, nix-ld, virtualisation, power

Each host selects a profile and a device module:

- **nesco** — desktopModules + `devices/zenbook_s16.nix` (Zen 5, AMD iGPU, asusd)
- **fresco** — desktopModules + `devices/fresco.nix` (Zen 4 + NVIDIA, performance tuning)
- **medesco** — serverModules only (no device module)

### Two-Layer Module System

**System modules** (`modules/`) configure NixOS options — hardware, services, kernel, system packages. They receive `inputs` and `system` via `specialArgs`.

**Home-manager modules** (`home/modules/`) configure user environment — programs, dotfiles, shell, editor. They receive `inputs` and `system` via `extraSpecialArgs`. All home modules are imported from `home/users/aidanb/default.nix`.

### Custom Options (`modules/profile.nix`)

Two custom options control conditional behavior across modules:

- `custom.hostType` — `"laptop"`, `"desktop"`, or `"server"` (controls TLP, sleep, power)
- `custom.display.type` — `"oled"` or `"lcd"` (controls font rendering / subpixel settings)

These are set in device modules and consumed by `sway.nix`, `power.nix`, etc.

### Per-Host Integration Pattern

Each host's `configuration.nix` does three things:
1. Imports `hardware-configuration.nix` (generated per-machine)
2. Imports its device module (e.g. `modules/devices/zenbook_s16.nix`)
3. Injects per-host home-manager overrides via `home-manager.users.aidanb.imports = [ ../../home/hosts/{host}.nix ]`

The per-host home files (`home/hosts/nesco.nix`, `home/hosts/fresco.nix`) override Sway and Waybar config sources to point to `config/sway/{host}/config` and `config/waybar/{host}/config`.

### CPU / GPU Module Hierarchy

CPU and GPU support is layered — device modules pick the pieces they need:

- `modules/amd/cpu.nix` — AMD microcode, `amd_pstate=active`, firmware (shared base)
- `modules/amd/zen4.nix` — Imports cpu.nix, sets `hostPlatform`, RUSTFLAGS, GOAMD64
- `modules/amd/zen5.nix` — Same pattern for znver5
- `modules/amd/graphics.nix` — AMDGPU driver, Mesa, VA-API (used by zenbook_s16)
- `modules/nvidia/gpu.nix` — NVIDIA open driver, VA-API/VDPAU, container toolkit, persistenced, shader cache, PAT (used by fresco)

Device modules compose these: `zenbook_s16.nix` imports `amd/graphics.nix` + `amd/cpu.nix`; `fresco.nix` imports `nvidia/gpu.nix` + `amd/zen4.nix`.

### Waybar Architecture

Waybar config is Nix-generated from a shared base + per-host deltas:
- `home/modules/wayland.nix` — defines `waybarBase` attrset (15 shared modules) and `custom.waybar.base`/`custom.waybar.hostOverrides` options; generates JSON via `builtins.toJSON (lib.recursiveUpdate base hostOverrides)`
- `home/hosts/nesco.nix` — sets `custom.waybar.hostOverrides` with battery/backlight/powerprofile, AMDGPU monitoring
- `home/hosts/fresco.nix` — sets `custom.waybar.hostOverrides` with disk monitoring, NVIDIA GPU monitoring
- `config/waybar/style.css` — shared styling
- `config/waybar/scripts/*.sh` — shell scripts for custom modules (sourced via `builtins.readFile` into `writeShellScriptBin`)

Custom modules use shell scripts calling `amdgpu_top`, `nvidia-smi`, `swaync-client`, `powerprofilesctl`, and a weather API.

### Key Modules

- `modules/base.nix` — Core system packages, zram swap (zstd, 50%), tmpfs /tmp, CUPS printing, local binary cache (`/mnt/nixos-cache`)
- `modules/networking.nix` — NetworkManager, encrypted DNS-over-TLS (1.1.1.1, 9.9.9.9), mDNS via Avahi, nftables firewall, SSH
- `modules/audio.nix` — PipeWire with Bluetooth codec support (SBC-XQ, LDAC, aptX, aptX-HD)
- `modules/sway.nix` — Enables Sway at system level with XDG portals, GNOME keyring, fonts (Nerd Fonts), font rendering conditioned on `custom.display.type`; auto-starts Sway on tty1
- `modules/kernel/cachyos.nix` — CachyOS kernel via nix-cachyos-kernel overlay (LTO default, zen4-lto for fresco), binary cache config
- `modules/secrets.nix` — SOPS-nix with age encryption for system-level secrets
- `modules/devices/zenbook_s16.nix` — AMD iGPU, asusd fan control, PSR disable, RCU tuning, resume device
- `modules/devices/fresco.nix` — Zen 4 + NVIDIA, imports tuning submodules (`tuning/workstation.nix`, `tuning/network.nix`, `tuning/io.nix`), earlyoom, WiFi ASPM workaround
- `home/modules/wayland.nix` — User-side Sway config, Waybar (Nix-generated base + per-host overrides), Wayland tools, Gammastep night light, HiDPI cursor, polkit agent
- `home/modules/devtools.nix` — Dev tools, Rust via rust-overlay, sccache, mold linker, antigravity/harbour build optimization
- `home/modules/claude.nix` — Claude Code ecosystem: claude-squad, tail-claude, claude-code-nix, mcp-nixos, notification hooks, OAuth token
- `home/modules/zed.nix` — Zed editor with vim mode and LSP configs (nixd, pyright, ruff, rust-analyzer)
- `home/modules/secrets.nix` — SOPS-nix home-manager module for user secrets

### Secrets

Encrypted secrets are managed by sops-nix with age encryption. Secrets live in `secrets/` (secrets.yaml for system, home.yaml for user). Key configuration is in `.sops.yaml`. The system keyfile is at `/var/lib/sops-nix/key.txt`, the user keyfile at `~/.config/sops/age/keys.txt`.

### Claude Code Integration

Claude Code is installed via the `claude-code-nix` flake input. Supporting tools are packaged as `buildGoModule` derivations in `home/modules/devtools.nix`:

- **claude-squad** (v1.0.16) — multi-session manager, built as `cs` binary with tmux/gh/git on PATH
- **tail-claude** (v0.3.5) — session log viewer
- **mcp-nixos** — NixOS MCP server, configured in `.mcp.json` at repo root

OAuth token is stored encrypted via sops-nix (`sops.secrets.claude_code_oauth_token`) and exported in `programs.zsh.profileExtra`. Agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

Notification hooks (`config/claude/hooks/notify.sh`) send desktop notifications via `notify-send` (swaync) on Stop/Notification events, with optional push via ntfy when `$NTFY_TOPIC` is set. The script is deployed to `~/.claude/hooks/` via `home.file`. Hook and sandbox config lives in `~/.claude/settings.json` (not Nix-managed).

### Flake Inputs of Note

- **nix-cachyos-kernel** (xddxdd/nix-cachyos-kernel) — CachyOS kernel packages with LTO and arch-specific variants; pinned to its own nixpkgs (must NOT follow our nixpkgs)
- **doom-flake** (local, `flakes/doom-emacs/`) — Doom Emacs with PGTK + native-comp
- **nixarr** — Media server stack (Jellyfin, Sonarr, Radarr, etc.)
- **sops-nix** — Encrypted secrets management
- **antigravity-nix**, **harbour** — Compilation optimization tools, exposed as packages in devtools
- **claude-code-nix** (sadjow/claude-code-nix) — Claude Code CLI package
- **rust-overlay** (oxalica/rust-overlay) — Rust toolchain management; replaces rustup with declarative `rust-bin.stable.latest.default`

### znver4 Build Issues (fresco)

Setting `hostPlatform.gcc.arch = "znver4"` compiles all packages with `-march=znver4`, enabling AVX-512. This causes test failures in several packages due to valgrind incompatibility, floating-point precision changes, and SIMD miscompilation. Workarounds are applied as overlays. See `hosts/fresco/README.md` for a full tracking table of affected packages and upstream issues.

### Patterns

- Modules use `let` blocks to organize package lists before assigning them
- `lib.mkForce` is used to override inherited defaults (e.g. fresco disables TLP, overrides OLED font rendering to LCD)
- Package overrides are done inline with `overrideAttrs` (see Cockatrice in `home/modules/gaming.nix`, Xen in `modules/virtualisation.nix`)
- Module composition profiles (serverModules, desktopModules) are defined in `flake.nix` and shared across hosts
- The user is `aidanb` with groups: wheel, docker, libvirtd, networkmanager, video

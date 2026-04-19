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
- `updaten` — `sudo nixos-rebuild switch --flake ~/System#$HOST --option substitute false` piped through `nom` (rebuild+switch from local store)
- `configure` — `nvim /etc/nixos/configuration.nix`
- `nix-sync-cache` — sync nix store to local binary cache at `/mnt/nixos-cache`
- `tc` — `tail-claude` (session log viewer)
- `rt` — `ralph-tui` (autonomous loop orchestrator)
- `hibernate` — `sudo systemctl hibernate`
- `shib` — `systemd-inhibit sleep infinity`

`loom` is shadowed by a `writeShellScriptBin` wrapper from `home/modules/claude.nix` that sets `LOOM_HOME` to `$GIT_ROOT/.loom` and auto-adds `.loom/` to the repo's `.gitignore` before exec'ing the underlying `loom` binary (itself wrapped by the upstream loom flake with `tmux`, `gh`, `git` on PATH).

## Architecture

### Host / Module Split

The flake defines a `mkHost` helper that combines a host-specific config with `commonModules` (profile.nix, rust-overlay overlay, nixarr, sops-nix, home-manager). Module composition is done via three profiles defined in `flake.nix`:

- **serverModules** — base, user, networking, terminal, mediaserver, secrets, benchmarking
- **htpcModules** — serverModules + openbox, audio, gaming, nix-ld
- **desktopModules** — serverModules + doom-flake, cachyos kernel, sway, audio, bluetooth, gaming, nix-ld, virtualisation, power

Each host selects a profile and a device module:

- **nesco** — desktopModules + `devices/zenbook_s16.nix` (Zen 5, AMD iGPU, asusd)
- **fresco** — desktopModules + `devices/fresco.nix` (Zen 4 + NVIDIA, performance tuning)
- **medesco** — htpcModules only (no device module — HTPC with Openbox X11 session)

**Distributed builds**: nesco is configured as a Nix client of fresco (`hosts/nesco/configuration.nix`) — SSH user `nixremote`, protocol `ssh-ng`, supports `big-parallel`/`kvm`/`nixos-test`/`benchmark`. Heavy builds triggered on nesco are offloaded to fresco.

### Two-Layer Module System

**System modules** (`modules/`) configure NixOS options — hardware, services, kernel, system packages. They receive `inputs` and `system` via `specialArgs`.

**Home-manager modules** (`home/modules/`) configure user environment — programs, dotfiles, shell, editor. They receive `inputs` and `system` via `extraSpecialArgs`. `home/users/aidanb/default.nix` imports the always-on base modules (shell, terminal, editor, git, ssh, development, devtools, claude, zed, secrets, gpg). Role-specific modules (wayland, apps, gaming, research, helix) are pulled in via `home/profiles/desktop.nix` through the per-host file.

**Home profiles** (`home/profiles/`) compose home modules into role-based sets. `home/profiles/desktop.nix` imports wayland, gaming, apps, research, and helix modules. Per-host files (`home/hosts/*.nix`) import a profile and then set host-specific overrides.

medesco is the exception: `home/hosts/medesco.nix` imports `apps.nix` and `gaming.nix` directly (no profile), and adds Openbox-specific config (tint2, feh, rofi, picom, Gruvbox theming).

### Custom Options (`modules/profile.nix`)

Four custom options control conditional behavior across modules:

- `custom.hostType` — `"laptop"`, `"desktop"`, or `"server"` (controls TLP, sleep, power)
- `custom.display.type` — `"oled"` or `"lcd"` (controls font rendering / subpixel settings)
- `custom.features.gaming` — bool, default true (controls Steam, Proton)
- `custom.features.virtualisation` — bool, default true (controls Docker, libvirt, KVM)

These are set in device modules and consumed by `sway.nix`, `power.nix`, `gaming.nix`, `virtualisation.nix`, etc.

### Per-Host Integration Pattern

Each host's `configuration.nix` does three things:
1. Imports `hardware-configuration.nix` (generated per-machine)
2. Imports its device module (e.g. `modules/devices/zenbook_s16.nix`)
3. Injects per-host home-manager overrides via `home-manager.users.aidanb.imports = [ ../../home/hosts/{host}.nix ]`

The per-host home files (`home/hosts/nesco.nix`, `home/hosts/fresco.nix`) import `home/profiles/desktop.nix`, then set host-specific overrides for Sway config sources (`config/sway/{host}/config`) and Waybar host overrides.

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
- `modules/openbox.nix` — Openbox X11 session (used by medesco HTPC)
- `modules/gaming.nix` — System-level gaming (Steam, Proton-GE, gated on `custom.features.gaming`)
- `modules/nix-ld.nix` — Dynamic-linker compatibility for non-Nix binaries
- `modules/tuning/{workstation,network,io}.nix` — Performance tuning submodules imported by `devices/fresco.nix`
- `modules/kernel/cachyos.nix` — CachyOS kernel via nix-cachyos-kernel overlay (LTO default, zen4-lto for fresco), binary cache config
- `modules/secrets.nix` — SOPS-nix with age encryption for system-level secrets
- `modules/devices/zenbook_s16.nix` — AMD iGPU, asusd fan control, PSR disable, RCU tuning, resume device
- `modules/devices/fresco.nix` — Zen 4 + NVIDIA, imports tuning submodules (`tuning/workstation.nix`, `tuning/network.nix`, `tuning/io.nix`), earlyoom, WiFi ASPM workaround
- `home/modules/wayland.nix` — User-side Sway config, Waybar (Nix-generated base + per-host overrides), Wayland tools, Gammastep night light, HiDPI cursor, polkit agent
- `home/modules/shell.nix` — Zsh + oh-my-zsh, shell aliases, SSH agent bootstrap, PATH for Doom Emacs
- `home/modules/terminal.nix` — Alacritty terminal config
- `home/modules/editor.nix` — Neovim config
- `home/modules/development.nix` — Direnv + nix-direnv
- `home/modules/ssh.nix` — User SSH client config
- `home/modules/gpg.nix` — GPG agent configuration
- `home/modules/devtools.nix` — Dev tools, Rust via rust-overlay, sccache, mold linker, antigravity/harbour build optimization
- `home/modules/claude.nix` — Claude Code ecosystem: loom, tail-claude, claude-code-nix, mcp-nixos, notification hooks, OAuth token
- `home/modules/zed.nix` — Zed editor with vim mode and LSP configs (nixd, pyright, ruff, rust-analyzer)
- `home/modules/secrets.nix` — SOPS-nix home-manager module for user secrets
- `home/modules/apps.nix` — User applications (Firefox, Discord, Spotify, Thunderbird, etc.) and MIME type defaults
- `home/modules/git.nix` — Git configuration
- `home/modules/helix.nix` — Helix editor configuration
- `home/modules/research.nix` — Research tools
- `home/modules/gaming.nix` — Home-level gaming packages (Steam, Proton, Lutris)
- `home/profiles/desktop.nix` — Desktop profile composing wayland, gaming, apps, research, helix modules

### Secrets

Encrypted secrets are managed by sops-nix with age encryption. Secrets live in `secrets/` (secrets.yaml for system, home.yaml for user). Key configuration is in `.sops.yaml`. The system keyfile is at `/var/lib/sops-nix/key.txt`, the user keyfile at `~/.config/sops/age/keys.txt`.

### Claude Code Integration

Claude Code is installed via the `claude-code-nix` flake input. Supporting tools in `home/modules/claude.nix`:

- **loom** — multi-session TUI for parallel AI coding agents (fork of claude-squad); tracked via `inputs.loom` flake input (`aidan-bailey/loom`), already wrapped by upstream with tmux/gh/git on PATH, and shadowed by a `loom` `writeShellScriptBin` wrapper that scopes `LOOM_HOME` to the current git root. Loom auto-migrates `~/.claude-squad/` → `~/.loom/` on first launch
- **tail-claude** (v0.3.5) — session log viewer, `buildGoModule` from `kylesnowschwartz/tail-claude`
- **mcp-nixos** — NixOS MCP server, configured in `.mcp.json` at repo root

OAuth token is stored encrypted via sops-nix (`sops.secrets.claude_code_oauth_token`) and exported in `programs.zsh.profileExtra`. Agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

Notification hooks (`config/claude/hooks/notify.sh`) send desktop notifications via `notify-send` (swaync) on Stop/Notification events, with optional push via ntfy when `$NTFY_TOPIC` is set. The script is deployed to `~/.claude/hooks/` via `home.file`. Gated by the `custom.claude.notifications` option (defined in `claude.nix`): `enable`, `channels.{desktop,push,popup}`, `events.{Stop,Notification}` — all default true except medesco where the default.nix disables it.

`~/.claude/settings.json` is Nix-generated from a `claudeSettings` attrset in `claude.nix` — model preference, hooks, enabled plugins, sandbox rules, effort level, and status line config are all declarative. It's installed via `home.activation` with `install -D -m 644` (writable at runtime, not a read-only symlink) so Claude Code can modify it. The `statusline.sh` script (`config/claude/statusline.sh`) is still a read-only symlink via `home.file`. The declarative plugin set includes superpowers, feature-dev, pr-review-toolkit, claude-md-management, skill-creator, code-simplifier, commit-commands, frontend-design, semgrep, sonatype-guide, claude-code-setup, context7, code-review, github, serena, explanatory-output-style, and language LSPs (rust-analyzer, pyright, gopls).

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

# Module Cleanup Design

Two refactors from the architecture review: split devtools.nix and consolidate Waybar configs into Nix.

## 1. Extract `home/modules/claude.nix`

Split Claude Code ecosystem out of `devtools.nix` into a peer module.

### claude.nix owns

- `claude-squad` and `tail-claude` `buildGoModule` package definitions
- `inputs.claude-code-nix.packages.${system}.default`
- Ecosystem packages: `mcp-nixos` (doCheck override), `jq`, `bun`
- Notification hook: `home.file.".claude/hooks/notify.sh"`
- SOPS secret: `sops.secrets.claude_code_oauth_token`
- zsh profileExtra for OAuth token export
- Session variable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- Session path: `$HOME/.bun/bin`

### devtools.nix keeps

- All language/build tooling (Rust, Python, Nix, JS, shell, DB, emulation, XML, markdown)
- antigravity-nix and harbour
- sccache, mold session variables (`LD`, `RUSTC_WRAPPER`)
- tmux config

### Integration

- `home/users/aidanb/default.nix` adds `claude.nix` to its imports list
- `claude.nix` takes `{ config, pkgs, lib, inputs, system, ... }` (needs `inputs`/`system` for claude-code-nix)
- `devtools.nix` retains `inputs`/`system` for antigravity-nix and harbour
- No inter-module dependency between claude.nix and devtools.nix

## 2. Waybar config: Nix base + per-host deltas

Replace three raw JSON files with Nix attrsets. Shared config lives in `wayland.nix`, per-host deltas live in `home/hosts/{host}.nix`.

### Mechanism

`wayland.nix` defines two custom home-manager options and generates the final config:

```nix
# In options:
options.custom.waybar.base = lib.mkOption {
  type = lib.types.attrs;
  default = waybarBase;  # from let block
  readOnly = true;
};

options.custom.waybar.hostOverrides = lib.mkOption {
  type = lib.types.attrs;
  default = {};
};

# In config:
xdg.configFile."waybar/config".text = builtins.toJSON
  (lib.recursiveUpdate config.custom.waybar.base config.custom.waybar.hostOverrides);
```

### Base config (in wayland.nix let block)

Contains all shared module definitions (~170 lines as Nix attrset):

- Bar structure: ipc, position ("bottom"), height (36), modules-left, modules-center
- Shared modules: sway/workspaces, sway/mode, sway/scratchpad, sway/window, mpd, idle_inhibitor, tray, clock, cpu, memory, network, pulseaudio, custom/swaync, custom/weather

Does NOT set: modules-right, margins, temperature critical threshold, or host-specific modules (gpu, backlight, battery, powerprofile, disk).

### Per-host deltas

**nesco** (`home/hosts/nesco.nix`) sets `custom.waybar.hostOverrides`:
- margins: 8, 12, 12
- modules-right: [..., backlight, battery, custom/powerprofile, custom/gpu, ...]
- temperature: critical-threshold 85
- backlight, battery, custom/powerprofile module definitions
- custom/gpu: waybar-amdgpu exec, amdgpu_top exec-if

**fresco** (`home/hosts/fresco.nix`) sets `custom.waybar.hostOverrides`:
- margins: 4, 6, 6
- modules-right: [..., disk, custom/gpu, ...]
- temperature: critical-threshold 90
- disk module definition
- custom/gpu: waybar-nvidiagpu exec, nvidia-smi exec-if

### List behavior

`lib.recursiveUpdate` replaces lists (no deep merge). This is correct for `modules-right` — each host defines its own module order entirely.

### Files deleted

- `config/waybar/config` (old dead base JSON)
- `config/waybar/nesco/config` (replaced by Nix attrset)
- `config/waybar/fresco/config` (replaced by Nix attrset)
- `config/waybar/nesco/` and `config/waybar/fresco/` directories

### Files kept

- `config/waybar/style.css` (shared styling, referenced unchanged)
- `config/waybar/scripts/*.sh` (still sourced via `builtins.readFile` in writeShellScriptBin)

### Per-host files simplified

`home/hosts/{nesco,fresco}.nix` no longer need `lib.mkForce` on waybar config — there's no conflicting base file assignment to override. They just set `custom.waybar.hostOverrides`.

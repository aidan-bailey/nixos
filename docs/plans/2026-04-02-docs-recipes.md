# docs/recipes/ Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a `docs/recipes/` directory with 8 topic areas, each containing a reference README and granular recipe files that teach LLMs how to modify this NixOS configuration.

**Architecture:** Each topic directory has a `README.md` (design reference + recipe index) and individual recipe `.md` files (one per modification task). CLAUDE.md gets a `## Recipes` section linking to all topics.

**Tech Stack:** Markdown documentation, Nix code examples drawn from existing codebase patterns.

---

### Task 1: Create directory skeleton and update CLAUDE.md

**Files:**
- Create: `docs/recipes/modules/`, `docs/recipes/hosts/`, `docs/recipes/devices/`, `docs/recipes/secrets/`, `docs/recipes/waybar/`, `docs/recipes/flake/`, `docs/recipes/kernel/`, `docs/recipes/claude/`
- Modify: `CLAUDE.md:187` (append after Patterns section)

**Step 1: Create all 8 directories**

```bash
mkdir -p docs/recipes/{modules,hosts,devices,secrets,waybar,flake,kernel,claude}
```

**Step 2: Add Recipes section to CLAUDE.md**

Append after line 187 (end of `### Patterns` section):

```markdown

## Recipes

Detailed modification guides live in `docs/recipes/`. Read the relevant recipe before making changes.

| Topic | When to read | Path |
|-------|-------------|------|
| Modules | Adding or modifying system/home-manager modules | `docs/recipes/modules/` |
| Hosts | Adding a host or changing host-specific config | `docs/recipes/hosts/` |
| Devices | Adding hardware support, CPU/GPU layers, workarounds | `docs/recipes/devices/` |
| Secrets | Working with sops-nix encrypted secrets | `docs/recipes/secrets/` |
| Waybar | Modifying status bar modules or scripts | `docs/recipes/waybar/` |
| Flake | Changing inputs, overlays, or the mkHost helper | `docs/recipes/flake/` |
| Kernel | Kernel variants, patches, CachyOS config | `docs/recipes/kernel/` |
| Claude | Claude Code settings, hooks, MCP servers | `docs/recipes/claude/` |
```

**Step 3: Commit**

```bash
git add docs/recipes/ CLAUDE.md
git commit -m "docs: create docs/recipes/ skeleton and link from CLAUDE.md"
```

---

### Task 2: Modules topic — README + 4 recipes

**Files:**
- Create: `docs/recipes/modules/README.md`
- Create: `docs/recipes/modules/add-system-module.md`
- Create: `docs/recipes/modules/add-home-module.md`
- Create: `docs/recipes/modules/add-custom-option.md`
- Create: `docs/recipes/modules/add-home-profile.md`

**Step 1: Write README.md**

```markdown
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
```

**Step 2: Write add-system-module.md**

```markdown
# Add a System Module

## When to use

When you need a new system-level NixOS module that configures hardware, services, or system packages.

## Files to modify

1. **Create** `modules/<name>.nix` — the new module
2. **Modify** `flake.nix` — add the module to the appropriate profile (`serverModules` or `desktopModules`)

## Steps

### 1. Create the module file

Follow the standard module pattern. Use a `let` block for package lists:

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  myPackages = with pkgs; [
    # packages here
  ];
in
{
  environment.systemPackages = myPackages;

  # services, boot params, etc.
}
```

### 2. Add to a profile in flake.nix

Add the module path to `serverModules` (all hosts) or `desktopModules` (desktop/laptop only):

```nix
# In flake.nix, inside the let block:
serverModules = commonModules ++ [
  ./modules/base.nix
  # ... existing modules ...
  ./modules/<name>.nix    # <-- add here
];
```

If the module should only apply to desktop hosts, add it to `desktopModules` instead.

### 3. If the module needs conditional behavior

Use existing custom options from `modules/profile.nix`:

```nix
{
  config = lib.mkIf config.custom.features.gaming {
    # only applied when gaming is enabled
  };
}
```

Or create a new custom option (see [Add a custom option](add-custom-option.md)).

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

All three hosts must build successfully. If the module is only in `desktopModules`, medesco won't include it but should still build.

## Gotchas

- System modules receive `inputs` and `system` via `specialArgs` — include them in the function signature if needed
- The module path in `flake.nix` must start with `./modules/`
- If adding packages that need unfree licenses, check that `nixpkgs.config.allowUnfree = true` is set (it is, in `commonModules`)
- Use `lib.mkDefault` for values that device modules or host configs might want to override
```

**Step 3: Write add-home-module.md**

```markdown
# Add a Home-Manager Module

## When to use

When you need a new user-level module that configures programs, dotfiles, shell settings, or user services.

## Files to modify

1. **Create** `home/modules/<name>.nix` — the new module
2. **Modify** one of:
   - `home/users/aidanb/default.nix` — if the module applies to all hosts (base modules)
   - `home/profiles/desktop.nix` — if the module only applies to desktop hosts

## Steps

### 1. Create the module file

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  myPackages = with pkgs; [
    # packages here
  ];
in
{
  home.packages = myPackages;

  # programs.<name>.enable = true;
  # xdg.configFile."<app>/config".source = ...;
}
```

### 2. Import the module

**For all hosts** — add to `home/users/aidanb/default.nix` imports:

```nix
imports = [
  ../../modules/shell.nix
  # ... existing imports ...
  ../../modules/<name>.nix    # <-- add here
];
```

Note: paths are relative from `home/users/aidanb/` to `home/modules/`.

**For desktop hosts only** — add to `home/profiles/desktop.nix`:

```nix
imports = [
  ../modules/wayland.nix
  # ... existing imports ...
  ../modules/<name>.nix    # <-- add here
];
```

Note: paths are relative from `home/profiles/` to `home/modules/`.

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
```

If added to `default.nix` (all hosts), also verify:
```bash
nixos-rebuild build --flake .#medesco
```

## Gotchas

- Home modules use `home.packages` not `environment.systemPackages`
- Home modules use `extraSpecialArgs` (not `specialArgs`) — same names (`inputs`, `system`) but different mechanism
- The import path differs depending on where you import from: `../../modules/` from `users/aidanb/`, `../modules/` from `profiles/`
- Do NOT import desktop-only modules (wayland, gaming) from `default.nix` — they belong in `profiles/desktop.nix`
- If the module defines custom options, they must be under a namespace (e.g., `custom.<feature>`)
```

**Step 4: Write add-custom-option.md**

```markdown
# Add a Custom Option

## When to use

When you need a new option that controls conditional behavior across multiple modules (e.g., enabling/disabling a feature set, or configuring a hardware property).

## Files to modify

1. **Modify** `modules/profile.nix` — define the new option
2. **Modify** device modules or host configs — set the option value
3. **Modify** consuming modules — use the option with `lib.mkIf` or direct access

## Steps

### 1. Add the option definition to profile.nix

Options live under `options.custom`. Follow the existing pattern:

**For a boolean feature flag:**

```nix
options.custom.features.myFeature = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable my feature set";
};
```

**For an enum:**

```nix
options.custom.myProperty = lib.mkOption {
  type = lib.types.enum [
    "optionA"
    "optionB"
  ];
  description = "Select the property type";
};
```

**For a nullable option (optional):**

```nix
options.custom.myProperty = lib.mkOption {
  type = lib.types.nullOr (lib.types.enum [
    "optionA"
    "optionB"
  ]);
  default = null;
  description = "Optional property";
};
```

### 2. Set the value in device modules or host configs

In a device module (e.g., `modules/devices/zenbook_s16.nix`):

```nix
custom.myProperty = "optionA";
```

Or in a host config (e.g., `hosts/nesco/configuration.nix`):

```nix
custom.features.myFeature = false;
```

### 3. Consume the option in modules

```nix
config = lib.mkIf config.custom.features.myFeature {
  # conditional config
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

## Gotchas

- `profile.nix` has NO config block — it only defines options
- All options must be under `options.custom` to avoid conflicts with NixOS options
- Non-nullable options without defaults must be set by every host that includes the module — prefer defaults or nullable types
- Boolean defaults should match the common case (e.g., `default = true` if most hosts want it)
```

**Step 5: Write add-home-profile.md**

```markdown
# Add a Home Profile

## When to use

When you need a new role-based composition of home-manager modules (e.g., a "server" profile that imports a different set of modules than the desktop profile).

## Files to modify

1. **Create** `home/profiles/<name>.nix` — the new profile
2. **Modify** per-host home files — import the new profile instead of or alongside `desktop.nix`

## Steps

### 1. Create the profile

Profiles are import-only files with no config. They compose modules:

```nix
{ ... }:
{
  imports = [
    ../modules/module-a.nix
    ../modules/module-b.nix
  ];
}
```

### 2. Import from per-host home files

In `home/hosts/<host>.nix`:

```nix
{
  imports = [ ../profiles/<name>.nix ];

  # host-specific overrides here
}
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

## Gotchas

- Profiles should NOT contain config — only imports
- Currently only `desktop.nix` exists; per-host files (`home/hosts/nesco.nix`, `home/hosts/fresco.nix`) import it
- medesco has no per-host home file because it uses `serverModules` (no desktop profile)
- If a module is needed by ALL hosts regardless of profile, it belongs in `home/users/aidanb/default.nix`, not in a profile
```

**Step 6: Commit**

```bash
git add docs/recipes/modules/
git commit -m "docs(recipes): add modules topic — reference and 4 recipes"
```

---

### Task 3: Hosts topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/hosts/README.md`
- Create: `docs/recipes/hosts/add-host.md`
- Create: `docs/recipes/hosts/modify-host-config.md`
- Create: `docs/recipes/hosts/add-host-home-overrides.md`

**Step 1: Write README.md**

```markdown
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
```

**Step 2: Write add-host.md**

```markdown
# Add a Host

## When to use

When setting up a new machine that will use this NixOS configuration.

## Files to modify

1. **Create** `hosts/<name>/configuration.nix` — host entry point
2. **Create** `hosts/<name>/hardware-configuration.nix` — generated on the target machine
3. **Optionally create** `home/hosts/<name>.nix` — per-host home-manager overrides (desktop hosts only)
4. **Optionally create** `modules/devices/<name>.nix` — hardware-specific module
5. **Modify** `flake.nix` — add the host to `nixosConfigurations`

## Steps

### 1. Generate hardware-configuration.nix on the target machine

```bash
sudo nixos-generate-config --show-hardware-config > hosts/<name>/hardware-configuration.nix
```

### 2. Create configuration.nix

Use an existing host as a template. Minimal desktop host:

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/devices/<name>.nix    # if you have a device module
  ];

  custom.hostType = "desktop";           # "laptop", "desktop", or "server"
  custom.display.type = "lcd";           # "oled" or "lcd"

  networking.hostName = "<name>";

  home-manager.users.aidanb.imports = [ ../../home/hosts/<name>.nix ];
}
```

Minimal server host (no device module, no home overrides):

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "<name>";
}
```

### 3. Create per-host home overrides (desktop hosts)

See [Add host home overrides](add-host-home-overrides.md).

### 4. Add to flake.nix

Add to the `nixosConfigurations` attrset:

```nix
nixosConfigurations = {
  nesco = mkHost { ... };
  fresco = mkHost { ... };
  medesco = mkHost { ... };
  <name> = mkHost {
    hostConfig = ./hosts/<name>/configuration.nix;
    profile = desktopModules;    # or serverModules
  };
};
```

### 5. Create a README (optional)

```bash
touch hosts/<name>/README.md
```

Document the hardware specs and any known issues.

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- `hardware-configuration.nix` must be generated on the actual target hardware — do not copy from another host
- The `networking.hostName` should match the flake attribute name
- Server hosts use `serverModules`, desktop/laptop hosts use `desktopModules`
- If adding a device module, it must be imported from `configuration.nix`, NOT added to profiles in `flake.nix`
- If the host uses distributed builds, pin the remote host's SSH key in `configuration.nix` (see nesco for example)
```

**Step 3: Write modify-host-config.md**

```markdown
# Modify Host Config

## When to use

When changing settings that are specific to a single host — boot parameters, distributed builds, SSH host keys, custom options.

## Files to modify

1. **Modify** `hosts/<name>/configuration.nix` — for system-level host settings
2. **Optionally modify** `home/hosts/<name>.nix` — for user-level host settings

## Steps

### 1. Identify what to change

Host configs handle settings that differ per machine:
- `custom.hostType` and `custom.display.type`
- Boot parameters (`boot.resumeDevice`, kernel params)
- Distributed build configuration
- SSH known hosts
- The `home-manager.users.aidanb.imports` line

Everything else should go in modules (system or device), not host configs.

### 2. Make the change

Host configs are standard NixOS configuration. Example — adding a kernel parameter:

```nix
boot.kernelParams = [ "my_param=value" ];
```

Example — adding a distributed build target:

```nix
nix.distributedBuilds = true;
nix.buildMachines = [{
  hostName = "remote-host";
  sshUser = "nixremote";
  protocol = "ssh-ng";
  systems = [ "x86_64-linux" ];
  maxJobs = 4;
  speedFactor = 2;
  supportedFeatures = [ "big-parallel" "kvm" ];
}];
```

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- Host config has higher priority than profile modules (it's first in the `mkHost` module list)
- Hardware-specific settings belong in device modules, not host configs
- Settings that apply to multiple hosts belong in shared modules, not duplicated in host configs
```

**Step 4: Write add-host-home-overrides.md**

```markdown
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
```

**Step 5: Commit**

```bash
git add docs/recipes/hosts/
git commit -m "docs(recipes): add hosts topic — reference and 3 recipes"
```

---

### Task 4: Devices topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/devices/README.md`
- Create: `docs/recipes/devices/add-device-module.md`
- Create: `docs/recipes/devices/add-kernel-workaround.md`
- Create: `docs/recipes/devices/add-gpu-support.md`

**Step 1: Write README.md**

```markdown
# Devices

## Overview

Read this when adding hardware support for a new machine, working around kernel/firmware bugs, or adding CPU/GPU driver support.

## Design

### CPU/GPU Module Hierarchy

CPU and GPU support is layered — device modules pick the pieces they need:

```
modules/amd/cpu.nix          ← shared base (microcode, amd_pstate, firmware)
├── modules/amd/zen4.nix     ← imports cpu.nix, sets RUSTFLAGS/GOAMD64 for znver4
└── modules/amd/zen5.nix     ← imports cpu.nix, sets RUSTFLAGS/GOAMD64 for znver5

modules/amd/graphics.nix     ← AMDGPU driver, Mesa, VA-API (orthogonal to CPU)
modules/nvidia/gpu.nix        ← NVIDIA driver, VA-API/VDPAU, container toolkit
```

Device modules import what they need:
- `zenbook_s16.nix` imports `amd/graphics.nix` + `amd/cpu.nix` (not zen5.nix — `-march=znver5` is disabled)
- `fresco.nix` imports `nvidia/gpu.nix` + `amd/zen4.nix` + tuning submodules

### Device Module Contract

A device module:
1. Imports the appropriate CPU and GPU modules
2. Sets hardware-specific kernel parameters
3. Configures power management (sleep, hibernate, lid behavior)
4. Enables hardware-specific services (e.g., `asusd` for ASUS laptops)
5. May import tuning submodules from `modules/tuning/`

Device modules are imported from host `configuration.nix`, NOT from profiles in `flake.nix`.

### Architecture-Specific Compilation

Both `zen4.nix` and `zen5.nix` have `gcc.arch` and `gcc.tune` **commented out** because setting them causes widespread test failures (valgrind, floating-point precision, SIMD issues). Instead, only `RUSTFLAGS` and `GOAMD64` environment variables are set.

See `hosts/fresco/README.md` for a tracking table of znver4-affected packages.

## Key Files

| File | Role |
|------|------|
| `modules/amd/cpu.nix` | Shared AMD CPU base (microcode, pstate, firmware) |
| `modules/amd/zen4.nix` | Zen 4 specific (imports cpu.nix) |
| `modules/amd/zen5.nix` | Zen 5 specific (imports cpu.nix) |
| `modules/amd/graphics.nix` | AMDGPU driver setup |
| `modules/nvidia/gpu.nix` | NVIDIA driver setup |
| `modules/devices/zenbook_s16.nix` | Laptop device module (AMD iGPU, asusd, Strix Point workarounds) |
| `modules/devices/fresco.nix` | Desktop device module (NVIDIA, tuning, remote builder) |
| `modules/tuning/` | Performance tuning submodules (workstation, network, io) |

## Recipes

- [Add a device module](add-device-module.md) — Create hardware support for a new machine
- [Add a kernel workaround](add-kernel-workaround.md) — Add kernel params or module options for hardware bugs
- [Add GPU support](add-gpu-support.md) — Add a new GPU driver configuration
```

**Step 2: Write add-device-module.md**

```markdown
# Add a Device Module

## When to use

When setting up a new machine with specific hardware that needs kernel parameters, driver configuration, or power management tuning.

## Files to modify

1. **Create** `modules/devices/<name>.nix` — the device module
2. **Modify** `hosts/<name>/configuration.nix` — import the device module

## Steps

### 1. Create the device module

Use `zenbook_s16.nix` (laptop) or `fresco.nix` (desktop) as a template:

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
{
  imports = [
    ../amd/cpu.nix          # or ../amd/zen4.nix, ../amd/zen5.nix
    ../amd/graphics.nix     # or ../nvidia/gpu.nix
  ];

  networking.hostName = "<name>";

  # Hardware-specific kernel parameters
  boot.kernelParams = [
    # workarounds go here
  ];

  # Power management (for laptops)
  services.logind = {
    lidSwitch = "hibernate";         # or "suspend"
    extraConfig = ''
      HandleLidSwitchExternalPower=suspend
      IdleAction=suspend
      IdleActionSec=30min
    '';
  };
}
```

### 2. Import from host configuration.nix

```nix
imports = [
  ./hardware-configuration.nix
  ../../modules/devices/<name>.nix
];
```

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- Device modules are imported from host configs, NOT from profile lists in `flake.nix`
- Choose the right CPU module: `cpu.nix` (base only), `zen4.nix` (Zen 4 + RUSTFLAGS), or `zen5.nix` (Zen 5 + RUSTFLAGS)
- GPU modules are orthogonal to CPU modules — import both
- For NVIDIA + Sway, add `programs.sway.extraOptions = [ "--unsupported-gpu" ];`
- Tuning submodules (`modules/tuning/`) are optional — only import if needed
- Document hardware workarounds with comments explaining the bug and linking upstream issues
```

**Step 3: Write add-kernel-workaround.md**

```markdown
# Add a Kernel Workaround

## When to use

When you need to work around a hardware or firmware bug using kernel parameters, module options, or boot configuration.

## Files to modify

1. **Modify** `modules/devices/<device>.nix` — add kernel params or module config

## Steps

### 1. Identify the workaround type

**Kernel boot parameters** — most common:

```nix
boot.kernelParams = [
  "amdgpu.dcdebugmask=0x600"     # disable PSR (panel self-refresh)
  "amdgpu.abmlevel=0"            # disable adaptive backlight
];
```

**Kernel module options** — for driver-level settings:

```nix
boot.extraModprobeConfig = ''
  options mt7921e power_save=0
'';
```

**initrd kernel modules** — for early driver loading:

```nix
boot.initrd.kernelModules = [ "amdgpu" ];
```

### 2. Add to the device module

Group workarounds together with comments documenting each bug:

```nix
# Strix Point AMDGPU workarounds
boot.kernelParams = [
  "amdgpu.dcdebugmask=0x600"              # disable PSR — causes flickering
  "amdgpu.sg_display=0"                    # scatter-gather display — causes flashing
  "amdgpu.ip_block_mask=0xffffbfff"        # disable VPE — broken s2idle resume
];
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying, verify the parameter took effect:

```bash
cat /proc/cmdline    # check kernel params
```

## Gotchas

- Always comment workarounds with what bug they fix — future you (or future LLM) needs to know when it's safe to remove
- Kernel params in `boot.kernelParams` are appended, not replaced — multiple modules can add params
- If a workaround is needed by multiple devices, consider putting it in a shared module under `modules/` rather than duplicating
- Track workarounds in the host's README.md (see `hosts/fresco/README.md` for the znver4 tracking table pattern)
```

**Step 4: Write add-gpu-support.md**

```markdown
# Add GPU Support

## When to use

When adding driver configuration for a new GPU type or modifying existing GPU settings.

## Files to modify

1. **Create or modify** `modules/<vendor>/gpu.nix` or `modules/amd/graphics.nix`
2. **Modify** `modules/devices/<device>.nix` — import the GPU module

## Steps

### 1. Follow the existing GPU module pattern

**AMD (modules/amd/graphics.nix):**

```nix
{
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.amdgpu.enable = lib.mkDefault true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ mesa libvdpau-va-gl libva-vdpau-driver ];
  };
  environment.variables.LIBVA_DRIVER_NAME = "radeonsi";
}
```

**NVIDIA (modules/nvidia/gpu.nix):**

```nix
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver libva-vdpau-driver ];
  };
}
```

### 2. Import from device module

```nix
imports = [
  ../amd/graphics.nix    # or ../nvidia/gpu.nix
];
```

### 3. Set environment variables for VA-API

AMD: `LIBVA_DRIVER_NAME = "radeonsi"`
NVIDIA: `LIBVA_DRIVER_NAME = "nvidia"`, plus GBM/GLX variables

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying:
```bash
vainfo           # verify VA-API
vulkaninfo       # verify Vulkan
```

## Gotchas

- NVIDIA + Sway requires `programs.sway.extraOptions = [ "--unsupported-gpu" ]` in the device module
- NVIDIA environment variables (`WLR_NO_HARDWARE_CURSORS`, `GBM_BACKEND`, etc.) are critical for Wayland
- GPU modules are orthogonal to CPU modules — a device imports both independently
- The NVIDIA package tracks `nvidiaPackages.beta` — check compatibility with the CachyOS kernel version
```

**Step 5: Commit**

```bash
git add docs/recipes/devices/
git commit -m "docs(recipes): add devices topic — reference and 3 recipes"
```

---

### Task 5: Secrets topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/secrets/README.md`
- Create: `docs/recipes/secrets/add-system-secret.md`
- Create: `docs/recipes/secrets/add-user-secret.md`
- Create: `docs/recipes/secrets/edit-secrets.md`

**Step 1: Write README.md**

```markdown
# Secrets

## Overview

Read this when working with encrypted secrets. This repo uses sops-nix with age encryption for both system-level and user-level secrets.

## Design

### Two Secret Scopes

**System secrets** — owned by root, available to NixOS services:
- File: `secrets/secrets.yaml`
- Key: `/var/lib/sops-nix/key.txt`
- Config: `modules/secrets.nix`
- Access: `config.sops.secrets.<name>`

**User secrets** — owned by the user, available in home-manager:
- File: `secrets/home.yaml`
- Key: `~/.config/sops/age/keys.txt`
- Config: `home/modules/secrets.nix`
- Access: `config.sops.secrets.<name>` (home-manager context)

### Key Management

Keys are defined in `.sops.yaml` with age key anchors. Each host has its own age key. Creation rules control which keys can decrypt which files:

- `secrets/secrets.yaml` → encrypted to both nesco and fresco keys
- `secrets/home.yaml` → encrypted to both keys
- `secrets/nesco.yaml` → encrypted to nesco key only (host-specific secrets)

### How Secrets Are Used

Secrets are decrypted at activation time and placed at a path (default: `/run/secrets/<name>` for system, `/run/user/<uid>/secrets/<name>` for user). Modules reference the path, not the value.

## Key Files

| File | Role |
|------|------|
| `.sops.yaml` | Key configuration and creation rules |
| `secrets/secrets.yaml` | Encrypted system secrets |
| `secrets/home.yaml` | Encrypted user secrets |
| `modules/secrets.nix` | System sops-nix config |
| `home/modules/secrets.nix` | User sops-nix config |

## Recipes

- [Add a system secret](add-system-secret.md) — Add a new system-level encrypted secret
- [Add a user secret](add-user-secret.md) — Add a new user-level encrypted secret
- [Edit secrets](edit-secrets.md) — Modify existing encrypted secret values
```

**Step 2: Write add-system-secret.md**

```markdown
# Add a System Secret

## When to use

When a NixOS service or system module needs access to an encrypted secret (API key, password, certificate, etc.).

## Files to modify

1. **Modify** `secrets/secrets.yaml` — add the secret value (via `sops`)
2. **Modify** the consuming module — declare and use the secret

## Steps

### 1. Add the secret to secrets.yaml

```bash
sops secrets/secrets.yaml
```

This opens the decrypted file in your editor. Add the new key:

```yaml
my_api_key: "the-actual-secret-value"
```

Save and close — sops re-encrypts automatically.

### 2. Declare the secret in the consuming module

```nix
sops.secrets.my_api_key = {
  # optional overrides:
  # owner = "someuser";
  # group = "somegroup";
  # mode = "0440";
};
```

### 3. Reference the secret path

```nix
services.myservice.apiKeyFile = config.sops.secrets.my_api_key.path;
```

The path defaults to `/run/secrets/my_api_key`.

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
sudo cat /run/secrets/my_api_key    # verify decryption
```

## Gotchas

- Secrets are files, not environment variables — services must support reading from a file path
- The `defaultSopsFile` is `secrets/secrets.yaml` — you don't need to specify `sopsFile` unless using a different file
- If adding a host-specific secret file, add a creation rule to `.sops.yaml` first
- Secret files in `/run/secrets/` are only readable by root by default — set `owner`/`mode` if a non-root service needs access
- The age key must exist on the target machine at `/var/lib/sops-nix/key.txt` before deployment
```

**Step 3: Write add-user-secret.md**

```markdown
# Add a User Secret

## When to use

When a user program or home-manager module needs access to an encrypted secret (OAuth tokens, API keys, etc.).

## Files to modify

1. **Modify** `secrets/home.yaml` — add the secret value (via `sops`)
2. **Modify** `home/modules/secrets.nix` or the consuming home module — declare and use the secret

## Steps

### 1. Add the secret to home.yaml

```bash
sops secrets/home.yaml
```

Add the new key:

```yaml
my_token: "the-actual-secret-value"
```

### 2. Declare the secret in a home module

```nix
sops.secrets.my_token = {
  # sopsFile is inherited from home/modules/secrets.nix defaultSopsFile
};
```

### 3. Reference the secret path

For environment variables (common pattern — see claude.nix OAuth token):

```nix
programs.zsh.envExtra = ''
  export MY_TOKEN="$(cat ${config.sops.secrets.my_token.path})"
'';
```

For config files:

```nix
home.file.".config/app/config".text = ''
  token_file = ${config.sops.secrets.my_token.path}
'';
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
cat $(cat /run/user/$(id -u)/secrets/my_token)    # verify decryption
```

## Gotchas

- User secrets use `secrets/home.yaml`, NOT `secrets/secrets.yaml`
- The user age key is at `~/.config/sops/age/keys.txt`, not the system key
- User secret paths are under `/run/user/<uid>/secrets/`, not `/run/secrets/`
- Reading secrets via `$(cat ...)` in shell envExtra works but happens at shell startup — if the secret changes, you need a new shell
- sops-nix for home-manager is loaded via `sharedModules` in `flake.nix` commonModules
```

**Step 4: Write edit-secrets.md**

```markdown
# Edit Secrets

## When to use

When you need to change the value of an existing encrypted secret.

## Files to modify

1. **Modify** `secrets/secrets.yaml` or `secrets/home.yaml` — via `sops`

## Steps

### 1. Open the encrypted file

```bash
sops secrets/secrets.yaml    # system secrets
sops secrets/home.yaml       # user secrets
```

### 2. Edit the value

The file opens decrypted in your editor. Change the value, save, and close. Sops re-encrypts automatically.

### 3. Rebuild

```bash
sudo nixos-rebuild switch --flake .#<host>
```

The new secret value is decrypted at activation time.

## Verification

After switching:
```bash
sudo cat /run/secrets/<secret_name>    # system secrets
```

## Gotchas

- You must have the age key on the machine where you run `sops` — it won't work without the decryption key
- After editing, the file will have new encrypted values in git — commit the change
- Do NOT edit the encrypted YAML directly — always use `sops` to open it
- If you need to add a new key to `.sops.yaml` (e.g., a new host), run `sops updatekeys secrets/secrets.yaml` after updating `.sops.yaml`
```

**Step 5: Commit**

```bash
git add docs/recipes/secrets/
git commit -m "docs(recipes): add secrets topic — reference and 3 recipes"
```

---

### Task 6: Waybar topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/waybar/README.md`
- Create: `docs/recipes/waybar/add-shared-module.md`
- Create: `docs/recipes/waybar/add-host-override.md`
- Create: `docs/recipes/waybar/add-custom-script.md`

**Step 1: Write README.md**

```markdown
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
```

**Step 2: Write add-shared-module.md**

```markdown
# Add a Shared Waybar Module

## When to use

When adding a Waybar module that should appear on all desktop hosts.

## Files to modify

1. **Modify** `home/modules/wayland.nix` — add the module definition to `waybarBase` and add the module name to a `modules-*` list

## Steps

### 1. Add module config to waybarBase

In the `waybarBase` attrset in `home/modules/wayland.nix`, add the module definition:

```nix
waybarBase = {
  # ... existing modules ...

  "my-module" = {
    format = "{usage}%";
    interval = 5;
    tooltip = true;
  };
};
```

### 2. Add to a modules list

Add the module name to `modules-left`, `modules-center`, or `modules-right` in `waybarBase`:

```nix
modules-right = [
  "tray"
  "my-module"    # <-- add here
  "clock"
];
```

**Note:** Per-host files override `modules-right` entirely — if you add a module to the shared base list, you must also add it to each host's override list, or hosts will lose it.

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
```

## Gotchas

- `modules-right` is typically overridden per-host — adding to the base list alone won't show the module on hosts that override the list
- Either add the module to all per-host `modules-right` lists, or only add it to the per-host lists (not the base)
- Module names with `/` (e.g., `sway/workspaces`) use the slash in the attrset key
- `lib.recursiveUpdate` merges recursively for attrsets but replaces lists entirely
```

**Step 3: Write add-host-override.md**

```markdown
# Add a Host-Specific Waybar Override

## When to use

When a Waybar module should only appear on one host, or when overriding a shared module's settings for a specific host.

## Files to modify

1. **Modify** `home/hosts/<host>.nix` — add or modify `custom.waybar.hostOverrides`

## Steps

### 1. Add the override

In the per-host home file, add to `custom.waybar.hostOverrides`:

**Adding a host-only module:**

```nix
custom.waybar.hostOverrides = {
  # Include it in modules-right (this REPLACES the base list)
  modules-right = [
    "tray"
    "cpu"
    "my-host-module"    # <-- new module
    "clock"
  ];

  # Define the module config
  "my-host-module" = {
    format = "{}";
    interval = 10;
  };
};
```

**Overriding a shared module's settings:**

```nix
custom.waybar.hostOverrides = {
  temperature.critical-threshold = 90;    # override just this field
};
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

## Gotchas

- `lib.recursiveUpdate` replaces lists entirely — if you override `modules-right`, you must include ALL modules you want, not just the new one
- Attrset values merge recursively — overriding `temperature.critical-threshold` doesn't remove other temperature settings
- Look at `home/hosts/nesco.nix` and `home/hosts/fresco.nix` for real examples
```

**Step 4: Write add-custom-script.md**

```markdown
# Add a Custom Waybar Script

## When to use

When adding a Waybar module that runs a shell script (e.g., monitoring, API calls, system queries).

## Files to modify

1. **Create** `config/waybar/scripts/<name>.sh` — the shell script
2. **Modify** `home/modules/wayland.nix` — wrap the script as a package and add the module config
3. **Modify** per-host files — add the module to `modules-right` if host-specific

## Steps

### 1. Write the shell script

Create `config/waybar/scripts/<name>.sh`:

```bash
#!/usr/bin/env bash
# Output JSON for Waybar
value=$(some-command)
echo "{\"text\": \"$value\", \"tooltip\": \"Details: $value\"}"
```

Waybar custom modules expect either plain text or JSON with `text`, `tooltip`, `class` fields.

### 2. Wrap as a package in wayland.nix

In the `home.packages` list in `home/modules/wayland.nix`, add:

```nix
(pkgs.writeShellScriptBin "waybar-<name>"
  (builtins.readFile ../../config/waybar/scripts/<name>.sh))
```

### 3. Add the module config

In `waybarBase` (if shared) or `custom.waybar.hostOverrides` (if host-specific):

```nix
"custom/<name>" = {
  exec = "waybar-<name>";
  return-type = "json";
  interval = 30;
  format = "{}";
};
```

### 4. Add to modules list

Add `"custom/<name>"` to `modules-right` in the appropriate location.

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying, test the script standalone:
```bash
waybar-<name>
```

## Gotchas

- Script files in `config/waybar/scripts/` are read at build time via `builtins.readFile` — changes require a rebuild
- The script name becomes the executable name (e.g., `waybar-weather` → `exec = "waybar-weather"`)
- Scripts should output valid JSON if using `return-type = "json"`
- Runtime dependencies (e.g., `nvidia-smi`, `amdgpu_top`) must be available on PATH — if needed, use `writeShellApplication` with `runtimeInputs` instead of `writeShellScriptBin`
- Add styling for the new module in `config/waybar/style.css` using `#custom-<name>` selector
```

**Step 5: Commit**

```bash
git add docs/recipes/waybar/
git commit -m "docs(recipes): add waybar topic — reference and 3 recipes"
```

---

### Task 7: Flake topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/flake/README.md`
- Create: `docs/recipes/flake/add-flake-input.md`
- Create: `docs/recipes/flake/add-overlay.md`
- Create: `docs/recipes/flake/update-inputs.md`

**Step 1: Write README.md**

```markdown
# Flake

## Overview

Read this when modifying flake inputs, overlays, or the host construction machinery. The flake is the top-level entry point that wires everything together.

## Design

### Structure

`flake.nix` has four main sections:

1. **Inputs** — external dependencies (nixpkgs, home-manager, kernel, tools)
2. **mkHost helper** — constructs a NixOS system from a host config + profile
3. **Module profiles** — `commonModules`, `serverModules`, `desktopModules`
4. **nixosConfigurations** — the three host outputs

### Input Pinning Strategy

Most inputs follow nixpkgs: `inputs.nixpkgs.follows = "nixpkgs"`. The notable exception is **nix-cachyos-kernel**, which pins its own nixpkgs and must NOT follow ours (the kernel build requires a specific nixpkgs version).

### Overlay Application

Overlays are applied in `commonModules` (available to all hosts):
- `rust-overlay` is applied in commonModules
- `nix-cachyos-kernel` overlay is applied in `modules/kernel/cachyos.nix`
- Package-level overlays for znver4 fixes are in host-specific config

### Module Composition

```
commonModules = [ profile.nix, rust-overlay, nixarr, sops-nix, home-manager ]
serverModules = commonModules ++ [ base, user, networking, terminal, mediaserver, secrets, benchmarking ]
desktopModules = serverModules ++ [ doom-flake, cachyos-kernel, sway, audio, bluetooth, gaming, nix-ld, virtualisation, power ]
```

`mkHost` combines: `[ hostConfig ] ++ profile ++ commonModules`

## Key Files

| File | Role |
|------|------|
| `flake.nix` | Everything — inputs, mkHost, profiles, outputs |
| `flake.lock` | Pinned input versions |

## Recipes

- [Add a flake input](add-flake-input.md) — Add a new external dependency
- [Add an overlay](add-overlay.md) — Apply a package overlay
- [Update inputs](update-inputs.md) — Update flake lock to newer versions
```

**Step 2: Write add-flake-input.md**

```markdown
# Add a Flake Input

## When to use

When adding a new external dependency — a NixOS module, package set, overlay, or tool that comes from another flake.

## Files to modify

1. **Modify** `flake.nix` — add the input and wire it into outputs
2. **Run** `nix flake lock` — update the lock file

## Steps

### 1. Add the input

In the `inputs` block of `flake.nix`:

```nix
inputs = {
  # ... existing inputs ...

  my-input = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";    # unless it needs its own nixpkgs
  };
};
```

### 2. Add to the outputs function signature

```nix
outputs = {
  nixpkgs,
  home-manager,
  # ... existing inputs ...
  my-input,
  ...
}:
```

### 3. Wire it in

**As a NixOS module** — add to the appropriate profile:

```nix
serverModules = commonModules ++ [
  my-input.nixosModules.default
  # ...
];
```

**As a package** — reference in a module:

```nix
home.packages = [
  inputs.my-input.packages.${system}.default
];
```

**As an overlay** — add to commonModules or a specific module:

```nix
nixpkgs.overlays = [ my-input.overlays.default ];
```

### 4. Update the lock file

```bash
nix flake lock
```

## Verification

```bash
nix flake check
nixos-rebuild build --flake .#nesco
```

## Gotchas

- Use `inputs.nixpkgs.follows = "nixpkgs"` unless the input needs its own nixpkgs (like nix-cachyos-kernel)
- The input name in `inputs = { ... }` must match the parameter name in `outputs = { ... }`
- `inputs` is available in system modules via `specialArgs` and in home modules via `extraSpecialArgs`
- Local flake inputs use `url = "path:./flakes/my-input"` (see `doom-flake`)
- After adding, run `nix flake lock` to generate the lock entry
```

**Step 3: Write add-overlay.md**

```markdown
# Add an Overlay

## When to use

When you need to override or extend packages in nixpkgs — patching a package, replacing a version, or adding custom derivations.

## Files to modify

1. **Modify** `flake.nix` or the relevant module — add the overlay

## Steps

### 1. Choose where to apply the overlay

**Global (all hosts)** — in `commonModules` or a module imported by all hosts:

```nix
nixpkgs.overlays = [
  (final: prev: {
    myPackage = prev.myPackage.overrideAttrs (old: {
      patches = old.patches or [] ++ [ ./patches/my-fix.patch ];
    });
  })
];
```

**Per-host** — in a device module or host config:

```nix
nixpkgs.overlays = [
  (final: prev: {
    # host-specific override
  })
];
```

### 2. Common overlay patterns

**Override package attributes:**

```nix
(final: prev: {
  myPackage = prev.myPackage.overrideAttrs (old: {
    version = "1.2.3";
    src = prev.fetchFromGitHub { ... };
  });
})
```

**Disable tests for a package (znver4 workaround pattern):**

```nix
(final: prev: {
  myPackage = prev.myPackage.overrideAttrs (old: {
    doCheck = false;
  });
})
```

**Apply an input's overlay:**

```nix
nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

## Gotchas

- `nixpkgs.overlays` is a list — multiple modules can each add overlays and they compose
- Overlay order matters for dependent overrides — overlays are applied left to right
- Use `final` (the fixed point, after all overlays) for dependencies and `prev` (before this overlay) for the package being overridden
- The CachyOS kernel overlay uses `inputs.nix-cachyos-kernel.overlays.pinned` — it's applied in `modules/kernel/cachyos.nix`, not in `flake.nix`
- For inline package overrides (one-off), prefer `overrideAttrs` directly in the module rather than a global overlay
```

**Step 4: Write update-inputs.md**

```markdown
# Update Flake Inputs

## When to use

When updating external dependencies to newer versions.

## Files to modify

1. **Modify** `flake.lock` — via `nix flake update` commands

## Steps

### Update all inputs

```bash
nix flake update
```

### Update a single input

```bash
nix flake update nixpkgs
nix flake update home-manager
```

### Pin an input to a specific revision

```bash
nix flake update my-input --override-input my-input github:owner/repo/<rev>
```

## Verification

```bash
nix flake check
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

Build all three hosts — input updates can break any of them.

## Gotchas

- nix-cachyos-kernel has its own nixpkgs pin — updating nixpkgs does NOT update the kernel's nixpkgs
- After `nix flake update`, always build all three hosts before switching — breakage is common
- The lock file can be large diffs — review `git diff flake.lock` to see what changed
- If a specific input update breaks a build, you can revert just that input: `nix flake update <input> --override-input <input> github:owner/repo/<old-rev>`
```

**Step 5: Commit**

```bash
git add docs/recipes/flake/
git commit -m "docs(recipes): add flake topic — reference and 3 recipes"
```

---

### Task 8: Kernel topic — README + 2 recipes

**Files:**
- Create: `docs/recipes/kernel/README.md`
- Create: `docs/recipes/kernel/change-kernel-variant.md`
- Create: `docs/recipes/kernel/add-kernel-patch.md`

**Step 1: Write README.md**

```markdown
# Kernel

## Overview

Read this when changing the kernel configuration. This repo uses the CachyOS kernel via the nix-cachyos-kernel overlay, with LTO and architecture-specific variants.

## Design

### CachyOS Kernel

The kernel is provided by the `nix-cachyos-kernel` flake input (xddxdd/nix-cachyos-kernel). It offers multiple variants:

- `linuxPackages-cachyos-latest-lto` — LTO-optimized, generic x86_64
- `linuxPackages-cachyos-latest-lto-zen4` — LTO + znver4 optimizations

The overlay is applied in `modules/kernel/cachyos.nix`, which also configures two Attic binary cache mirrors for pre-built kernels.

### Current Configuration

- Default: `cachyosKernels.linuxPackages-cachyos-latest-lto-zen4` (via `lib.mkDefault`)
- The `lib.mkDefault` allows device modules to override the variant
- Binary caches reduce build time significantly (kernel builds are expensive)

### Critical Constraint

The nix-cachyos-kernel input pins its own nixpkgs and must NOT follow our nixpkgs. This is enforced in `flake.nix` — nix-cachyos-kernel is the only input without `inputs.nixpkgs.follows`.

## Key Files

| File | Role |
|------|------|
| `modules/kernel/cachyos.nix` | Kernel package selection, overlay, binary cache |
| `flake.nix` | nix-cachyos-kernel input (lines 12-15) |

## Recipes

- [Change kernel variant](change-kernel-variant.md) — Switch between CachyOS kernel variants
- [Add a kernel patch](add-kernel-patch.md) — Apply a custom kernel patch
```

**Step 2: Write change-kernel-variant.md**

```markdown
# Change Kernel Variant

## When to use

When switching between CachyOS kernel variants (e.g., generic LTO vs. znver4-optimized).

## Files to modify

1. **Modify** `modules/kernel/cachyos.nix` — change the default variant
2. **Or modify** a device module — override for a specific host

## Steps

### Change the default for all hosts

In `modules/kernel/cachyos.nix`:

```nix
boot.kernelPackages = lib.mkDefault pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto;
```

Available variants (check the nix-cachyos-kernel repo for current list):
- `linuxPackages-cachyos-latest-lto` — generic LTO
- `linuxPackages-cachyos-latest-lto-zen4` — LTO + znver4

### Override for a specific host

In a device module (e.g., `modules/devices/fresco.nix`):

```nix
boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;
```

Without `lib.mkDefault`, this takes priority over the default in `cachyos.nix`.

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying:
```bash
uname -r    # verify kernel version
```

## Gotchas

- The default uses `lib.mkDefault` specifically so device modules can override without `lib.mkForce`
- Binary caches may not have all variants pre-built — unfamiliar variants will build from source (slow)
- Kernel variant changes require a reboot to take effect
- The nix-cachyos-kernel overlay must be `overlays.pinned`, not `overlays.default`
```

**Step 3: Write add-kernel-patch.md**

```markdown
# Add a Kernel Patch

## When to use

When applying a custom patch to the CachyOS kernel (e.g., hardware fix not yet upstream).

## Files to modify

1. **Create** the patch file (e.g., `modules/kernel/patches/my-fix.patch`)
2. **Modify** `modules/kernel/cachyos.nix` or a device module — apply the patch

## Steps

### 1. Add the patch file

Place the patch in `modules/kernel/patches/`:

```bash
mkdir -p modules/kernel/patches
```

### 2. Apply the patch

In `modules/kernel/cachyos.nix` (all hosts) or a device module (specific host):

```nix
boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto.extend (self: super: {
  kernel = super.kernel.overrideAttrs (old: {
    patches = old.patches or [] ++ [ ./patches/my-fix.patch ];
  });
});
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

Building a patched kernel compiles from source — this will be slow.

## Gotchas

- Patching the kernel disables binary cache hits — the patched kernel must build from source
- Patches must apply cleanly against the current CachyOS kernel version — they may break on kernel updates
- Consider whether a kernel parameter (see [Add a kernel workaround](../devices/add-kernel-workaround.md)) would achieve the same goal without a custom build
- Document patches with comments explaining the upstream issue and when the patch can be removed
```

**Step 4: Commit**

```bash
git add docs/recipes/kernel/
git commit -m "docs(recipes): add kernel topic — reference and 2 recipes"
```

---

### Task 9: Claude topic — README + 3 recipes

**Files:**
- Create: `docs/recipes/claude/README.md`
- Create: `docs/recipes/claude/modify-claude-settings.md`
- Create: `docs/recipes/claude/add-hook.md`
- Create: `docs/recipes/claude/add-mcp-server.md`

**Step 1: Write README.md**

```markdown
# Claude

## Overview

Read this when modifying Claude Code configuration — settings, hooks, MCP servers, or supporting tools. All Claude Code config is Nix-generated and deployed as read-only store symlinks.

## Design

### Declarative Settings

`~/.claude/settings.json` is generated from a `claudeSettings` attrset in `home/modules/claude.nix`. It includes:
- Model preference (`opus`)
- Hooks (notification hooks, conditionally generated)
- Enabled plugins
- Sandbox rules (network allowlist, filesystem deny)
- Effort level
- Status line config

The file is a read-only nix store symlink — you cannot edit it manually. All changes must go through `claude.nix`.

### Notification Hooks

Hooks are conditionally generated based on `custom.claude.notifications` options:
- Three channels: desktop, push, popup
- Two event types: Stop, Notification
- Hook script: `config/claude/hooks/notify.sh`
- Config file: generated `notify.conf` with channel enable flags

Currently **disabled** in `home/users/aidanb/default.nix`.

### Supporting Tools

| Tool | Source | Role |
|------|--------|------|
| claude-code-nix | flake input | Claude Code CLI |
| claude-squad | flake input, wrapped | Multi-session manager |
| tail-claude | buildGoModule | Session log viewer |
| mcp-nixos | flake input | NixOS MCP server |

### Environment Variables

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true"` — enables agent teams
- `CLAUDE_CODE_EFFORT_LEVEL = "max"` — overrides the `effortLevel` in settings
- `CLAUDE_CODE_OAUTH_TOKEN` — from sops-nix encrypted secret

## Key Files

| File | Role |
|------|------|
| `home/modules/claude.nix` | Main config: settings, hooks, tools, secrets |
| `config/claude/hooks/notify.sh` | Notification hook script |
| `config/claude/statusline.sh` | Status line script |
| `home/users/aidanb/default.nix` | Notification enable/disable |
| `.mcp.json` | MCP server config (repo-level) |

## Recipes

- [Modify Claude settings](modify-claude-settings.md) — Change settings.json via the Nix attrset
- [Add a hook](add-hook.md) — Add a new Claude Code hook
- [Add an MCP server](add-mcp-server.md) — Add a new MCP server
```

**Step 2: Write modify-claude-settings.md**

```markdown
# Modify Claude Settings

## When to use

When changing Claude Code settings — model, effort level, plugins, sandbox rules, or any other `settings.json` field.

## Files to modify

1. **Modify** `home/modules/claude.nix` — update the `claudeSettings` attrset

## Steps

### 1. Find the claudeSettings attrset

In `home/modules/claude.nix`, the `claudeSettings` attrset is in the `let` block. It maps directly to `~/.claude/settings.json`.

### 2. Make the change

**Change model:**

```nix
claudeSettings = {
  model = "sonnet";    # was "opus"
  # ...
};
```

**Add a sandbox rule:**

```nix
sandbox = {
  network = {
    allow = [
      "github.com"
      "new-domain.com"    # <-- add here
    ];
  };
  filesystem = {
    deny = [
      "~/.ssh"
      "/new/path"    # <-- add here
    ];
  };
};
```

**Enable/disable a plugin:**

```nix
enabledPlugins = {
  "plugin-name" = true;     # enable
  "other-plugin" = false;   # disable
};
```

**Change effort level:**

The effort level is set in TWO places:
- `claudeSettings.effortLevel = "high"` — in settings.json
- `CLAUDE_CODE_EFFORT_LEVEL = "max"` — env var in sessionVariables (overrides settings)

To change effective effort, modify the env var:

```nix
home.sessionVariables = {
  CLAUDE_CODE_EFFORT_LEVEL = "high";    # was "max"
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying, check the generated file:
```bash
cat ~/.claude/settings.json | jq .
```

## Gotchas

- `~/.claude/settings.json` is a read-only nix store symlink — you CANNOT edit it manually
- The `CLAUDE_CODE_EFFORT_LEVEL` env var overrides `effortLevel` in settings — check both
- The `hooks` field is conditionally generated from notification options — don't add hooks directly to `claudeSettings.hooks` (use the hook options instead, or see [Add a hook](add-hook.md))
- After rebuilding, you may need to restart Claude Code for settings to take effect
```

**Step 3: Write add-hook.md**

```markdown
# Add a Hook

## When to use

When adding a new Claude Code hook — a script that runs in response to Claude Code events (Stop, Notification, etc.).

## Files to modify

1. **Create** `config/claude/hooks/<name>.sh` — the hook script
2. **Modify** `home/modules/claude.nix` — add the hook to `claudeSettings.hooks` or the notification system

## Steps

### 1. Write the hook script

Create `config/claude/hooks/<name>.sh`:

```bash
#!/usr/bin/env bash
# Hook receives event data via environment variables
# See Claude Code docs for available variables
```

### 2. Deploy the script via home.file

In `home/modules/claude.nix`, add to the config block:

```nix
home.file.".claude/hooks/<name>.sh" = {
  source = ../../config/claude/hooks/<name>.sh;
  executable = true;
};
```

### 3. Add to claudeSettings.hooks

For notification-style hooks, use the existing `custom.claude.notifications` options.

For other hooks, add directly to the hooks in the `claudeSettings` attrset:

```nix
hooks = {
  # ... existing hooks ...
  MyEvent = [
    {
      type = "command";
      command = "~/.claude/hooks/<name>.sh";
    }
  ];
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
ls -la ~/.claude/hooks/    # verify script is deployed
cat ~/.claude/settings.json | jq '.hooks'    # verify hook is registered
```

## Gotchas

- Hook scripts must be executable — use `executable = true` in `home.file`
- The notification hook system (`custom.claude.notifications`) is separate from direct hook entries — don't mix them
- Notification hooks are currently disabled in `home/users/aidanb/default.nix` (`custom.claude.notifications.enable = false`)
- Hook scripts are deployed as nix store symlinks — changes require a rebuild
- The `hooks` field in `claudeSettings` is conditionally generated — if notification hooks are enabled, they're merged in. Adding hooks directly requires understanding this merge logic.
```

**Step 4: Write add-mcp-server.md**

```markdown
# Add an MCP Server

## When to use

When adding a new MCP (Model Context Protocol) server that Claude Code can use for tool access.

## Files to modify

1. **Modify** `.mcp.json` — add the server config (repo-level)
2. **Optionally modify** `home/modules/claude.nix` — if the server needs a package installed

## Steps

### 1. Add server to .mcp.json

`.mcp.json` in the repo root configures MCP servers:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "my-server-command",
      "args": ["--flag", "value"]
    }
  }
}
```

### 2. Install the server package (if needed)

In `home/modules/claude.nix`, add to `home.packages`:

```nix
home.packages = [
  # ... existing packages ...
  inputs.my-server.packages.${system}.default
  # or
  pkgs.my-server-package
];
```

### 3. For npx-based servers

Many MCP servers run via npx:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@scope/mcp-server-name"]
    }
  }
}
```

## Verification

```bash
nixos-rebuild build --flake .#nesco    # if package was added
```

Test the MCP server manually:
```bash
my-server-command --help
```

## Gotchas

- `.mcp.json` is a repo-level file, not Nix-generated — it can be edited directly
- The current `mcp-nixos` server is installed as a package with `doCheck = false` (tests disabled) — some MCP packages may need similar treatment
- MCP servers need their runtime dependencies on PATH — check that all required tools are in `home.packages`
- For servers that need API keys, consider using sops-nix secrets (see [Add a user secret](../secrets/add-user-secret.md))
```

**Step 5: Commit**

```bash
git add docs/recipes/claude/
git commit -m "docs(recipes): add claude topic — reference and 3 recipes"
```

---

### Task 10: Final review and format check

**Step 1: Verify all files exist**

```bash
find docs/recipes -name "*.md" | sort
```

Expected output:
```
docs/recipes/claude/README.md
docs/recipes/claude/add-hook.md
docs/recipes/claude/add-mcp-server.md
docs/recipes/claude/modify-claude-settings.md
docs/recipes/devices/README.md
docs/recipes/devices/add-device-module.md
docs/recipes/devices/add-gpu-support.md
docs/recipes/devices/add-kernel-workaround.md
docs/recipes/flake/README.md
docs/recipes/flake/add-flake-input.md
docs/recipes/flake/add-overlay.md
docs/recipes/flake/update-inputs.md
docs/recipes/hosts/README.md
docs/recipes/hosts/add-host-home-overrides.md
docs/recipes/hosts/add-host.md
docs/recipes/hosts/modify-host-config.md
docs/recipes/kernel/README.md
docs/recipes/kernel/add-kernel-patch.md
docs/recipes/kernel/change-kernel-variant.md
docs/recipes/modules/README.md
docs/recipes/modules/add-custom-option.md
docs/recipes/modules/add-home-module.md
docs/recipes/modules/add-home-profile.md
docs/recipes/modules/add-system-module.md
docs/recipes/secrets/README.md
docs/recipes/secrets/add-system-secret.md
docs/recipes/secrets/add-user-secret.md
docs/recipes/secrets/edit-secrets.md
docs/recipes/waybar/README.md
docs/recipes/waybar/add-custom-script.md
docs/recipes/waybar/add-host-override.md
docs/recipes/waybar/add-shared-module.md
```

35 files total (8 READMEs + 27 recipes).

**Step 2: Verify CLAUDE.md has the Recipes section**

```bash
grep -n "## Recipes" CLAUDE.md
```

**Step 3: Run nixfmt to ensure no formatting issues in nix code blocks (manual check)**

Verify all nix code examples in recipes use correct syntax by reviewing each file.

**Step 4: Commit any fixes**

```bash
git add -A docs/recipes/ CLAUDE.md
git commit -m "docs(recipes): final review and formatting fixes"
```

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

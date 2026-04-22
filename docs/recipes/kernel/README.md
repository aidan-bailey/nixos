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

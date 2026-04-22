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

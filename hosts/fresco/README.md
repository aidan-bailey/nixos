# fresco

Desktop workstation — AMD Zen 4 + NVIDIA on MSI B650M Mortar WiFi.

## Profile

**desktopModules** — full desktop with Sway, gaming, audio, Bluetooth, virtualisation, power management, and media server.

## Device Module

`modules/devices/fresco.nix` — imports `nvidia/gpu.nix` and `amd/zen4.nix`, then layers fresco-specific tuning:

- **CPU**: `znver4` arch/tune via `hostPlatform.gcc`, kernel `KCFLAGS`, `RUSTFLAGS`, and `GOAMD64=v4`; performance governor + EPP forced to `performance`
- **GPU**: NVIDIA open driver (stable), Sway `--unsupported-gpu`, VA-API/VDPAU, container toolkit, persistenced, PAT, fbdev, shader cache
- **Memory/VM**: THP madvise, zram-tuned sysctls (`swappiness=180`, `page-cluster=0`), compaction/watermark boost disabled, `max_map_count=1048576`
- **Scheduler**: sched-ext `scx_lavd`, `sched_autogroup`, irqbalance, NMI watchdog off
- **Network**: TCP BBR + fq qdisc, TFO, 16 MB buffer caps, WiFi RPS across 8 cores
- **Storage**: NVMe scheduler `none`, EXT4 `noatime,commit=60`, weekly fstrim
- **WiFi**: MT7922 ASPM disabled for stability
- **Fonts**: LCD subpixel rendering (rgb + lcdfilter default)
- **OOM**: earlyoom (5% mem / 10% swap), prefers killing compilers, avoids desktop apps
- **Nix build**: 4 jobs x 4 cores, batch CPU + best-effort IO scheduling for daemon
- **Boot**: `iommu=pt`, `split_lock_detect=off`, `workqueue.power_efficient=0`
- **Housekeeping**: journal capped at 500M / 1 month, TLP force-disabled

## Hardware

- **CPU**: AMD Ryzen 7 7700X (8C/16T, Zen 4)
- **GPU**: MSI RTX 3070 GAMING X TRIO
- **Motherboard**: MSI B650M Mortar WiFi
- **WiFi**: MediaTek MT7922/mt7921e
- **RAM**: 32 GB DDR5-6000
- **Storage**: NVMe (EXT4) + 1TB secondary (`/tb`)

## Known `gcc.arch = "znver4"` Build Issues

Setting `hostPlatform.gcc.arch = "znver4"` compiles all packages with `-march=znver4`, enabling AVX-512 and FMA instructions. This causes test failures in several packages, worked around via overlays in `modules/base.nix`.

### Valgrind (no AVX-512 support)

Valgrind does not support AVX-512 instructions, so any package running valgrind during tests will fail with SIGILL. There is no upstream fix ([nixpkgs#251673](https://github.com/NixOS/nixpkgs/issues/251673)).

| Package | Issue | Status |
|---------|-------|--------|
| rapidjson | [nixpkgs#451374](https://github.com/NixOS/nixpkgs/issues/451374) | Fixed in nixpkgs (doCheck gates on `availableOn`) |

### Floating-point precision

AVX-512/FMA changes FFT and math rounding beyond tight test tolerances.

| Package | Issue | Status |
|---------|-------|--------|
| scipy `test_roundtrip_scaling` | No upstream issue | Override in `base.nix` |
| numpy `test_validate_transcendentals` | [nixpkgs#275626](https://github.com/NixOS/nixpkgs/issues/275626) | Fixed in nixpkgs ([PR #398569](https://github.com/NixOS/nixpkgs/pull/398569)) |
| gsl | [nixpkgs#474185](https://github.com/NixOS/nixpkgs/issues/474185) | Open, no fix |
| opencolorio | [nixpkgs#398621](https://github.com/NixOS/nixpkgs/issues/398621) | Open, GCC bug |
| lib2geom | [nixpkgs#413230](https://github.com/NixOS/nixpkgs/issues/413230) | Open, fix [PR #398581](https://github.com/NixOS/nixpkgs/pull/398581) not merged |
| libreoffice | [nixpkgs#398633](https://github.com/NixOS/nixpkgs/issues/398633) | Open, no fix |

### Miscompilation / SIMD

| Package | Issue | Status |
|---------|-------|--------|
| assimp | [nixpkgs#440270](https://github.com/NixOS/nixpkgs/issues/440270) | Open, likely [GCC#122304](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=122304) |
| libvorbis | [nixpkgs#317161](https://github.com/NixOS/nixpkgs/issues/317161) | Closed as won't fix |
| ffmpeg `huffyuvbgra` | [nixpkgs#398625](https://github.com/NixOS/nixpkgs/issues/398625) | Possibly fixed by GCC 15 |

### Crypto / TLS

| Package | Issue | Status |
|---------|-------|--------|
| gnutls | [nixpkgs#440279](https://github.com/NixOS/nixpkgs/issues/440279) | Open |
| libsecret | [nixpkgs#452157](https://github.com/NixOS/nixpkgs/issues/452157) | Open |

### Other

| Package | Issue | Status |
|---------|-------|--------|
| OVMF | [nixpkgs#381223](https://github.com/NixOS/nixpkgs/issues/381223) | Open, UEFI firmware should not use march flags |
| anyio `test_multiple_threads` | [nixpkgs#448125](https://github.com/NixOS/nixpkgs/issues/448125) | Fixed in nixpkgs ([PR #451746](https://github.com/NixOS/nixpkgs/pull/451746)) |
| tornado `test_gc` | [nixpkgs#451233](https://github.com/NixOS/nixpkgs/issues/451233) | Fixed in nixpkgs ([PR #481981](https://github.com/NixOS/nixpkgs/pull/481981)) |

## Build

```bash
sudo nixos-rebuild switch --flake .#fresco
```

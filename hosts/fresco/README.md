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
- **GPU**: NVIDIA RTX 3070
- **Motherboard**: MSI B650M Mortar WiFi
- **WiFi**: MediaTek MT7922/mt7921e
- **Storage**: NVMe (EXT4) + 1TB secondary (`/tb`)

## Build

```bash
sudo nixos-rebuild switch --flake .#fresco
```

# fresco

Desktop workstation — AMD Zen 4 + NVIDIA on MSI B650M Mortar WiFi.

## Profile

**desktopModules** — full desktop with Sway, gaming, audio, Bluetooth, virtualisation, power management, and media server.

## Device Module

`modules/devices/fresco.nix` — Zen 4 CPU optimizations (`-march=znver4`), NVIDIA GPU (Sway with `--unsupported-gpu`), LCD subpixel font rendering, MT7922 WiFi ASPM workaround, performance CPU governor, NVMe I/O scheduler tuning, earlyoom, and workstation build settings (4 jobs x 4 cores).

## Hardware

- **CPU**: AMD Ryzen 7 7700X
- **GPU**: NVIDIA RTX 3070
- **Motherboard**: MSI B650M Mortar WiFi
- **WiFi**: MediaTek MT7922/mt7921e
- **Storage**: NVMe (EXT4) + 1TB secondary (`/tb`)

## Build

```bash
sudo nixos-rebuild switch --flake .#fresco
```

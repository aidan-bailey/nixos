# nesco

Primary laptop — ASUS Zenbook S16 (UM5606WA), AMD Zen 5.

## Profile

**desktopModules** — full desktop with Sway, gaming, audio, Bluetooth, virtualisation, power management, and media server.

## Device Module

Imports `modules/devices/zenbook_s16.nix`, which adds:

- AMDGPU + AMD CPU drivers
- asusd daemon for fan profiles and platform switching
- Kernel params: Panel Self Refresh disabled (`amdgpu.dcdebugmask=0x600`), scatter/gather display fix, RCU lazy batching
- Hibernate resume partition

## Hardware

- **CPU:** AMD Ryzen (Zen 5), KVM-AMD
- **Storage:** NVMe (ext4 root, vfat ESP boot)
- **Connectivity:** Thunderbolt, USB, SD card reader
- **Display:** OLED, 1.5x HiDPI scaling, adaptive sync

## Build

```bash
sudo nixos-rebuild switch --flake .#nesco
```

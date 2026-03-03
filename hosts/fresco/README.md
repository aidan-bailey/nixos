# fresco

Secondary system — same desktop stack as nesco without device-specific tweaks.

## Profile

**desktopModules** — full desktop with Sway, gaming, audio, Bluetooth, virtualisation, power management, and media server.

## Device Module

None. Uses the desktop module profile directly without any hardware-specific overrides. The `hardware-configuration.nix` should be regenerated with `nixos-generate-config` for the target machine.

## Build

```bash
sudo nixos-rebuild switch --flake .#fresco
```

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

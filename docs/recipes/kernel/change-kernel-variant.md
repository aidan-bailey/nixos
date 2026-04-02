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

# Add a Kernel Patch

## When to use

When applying a custom patch to the CachyOS kernel (e.g., hardware fix not yet upstream).

## Files to modify

1. **Create** the patch file (e.g., `modules/kernel/patches/my-fix.patch`)
2. **Modify** `modules/kernel/cachyos.nix` or a device module — apply the patch

## Steps

### 1. Add the patch file

Place the patch in `modules/kernel/patches/`:

```bash
mkdir -p modules/kernel/patches
```

### 2. Apply the patch

In `modules/kernel/cachyos.nix` (all hosts) or a device module (specific host):

```nix
boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto.extend (self: super: {
  kernel = super.kernel.overrideAttrs (old: {
    patches = old.patches or [] ++ [ ./patches/my-fix.patch ];
  });
});
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

Building a patched kernel compiles from source — this will be slow.

## Gotchas

- Patching the kernel disables binary cache hits — the patched kernel must build from source
- Patches must apply cleanly against the current CachyOS kernel version — they may break on kernel updates
- Consider whether a kernel parameter (see [Add a kernel workaround](../devices/add-kernel-workaround.md)) would achieve the same goal without a custom build
- Document patches with comments explaining the upstream issue and when the patch can be removed

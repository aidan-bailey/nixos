# Add an Overlay

## When to use

When you need to override or extend packages in nixpkgs — patching a package, replacing a version, or adding custom derivations.

## Files to modify

1. **Modify** `flake.nix` or the relevant module — add the overlay

## Steps

### 1. Choose where to apply the overlay

**Global (all hosts)** — in `commonModules` or a module imported by all hosts:

```nix
nixpkgs.overlays = [
  (final: prev: {
    myPackage = prev.myPackage.overrideAttrs (old: {
      patches = old.patches or [] ++ [ ./patches/my-fix.patch ];
    });
  })
];
```

**Per-host** — in a device module or host config:

```nix
nixpkgs.overlays = [
  (final: prev: {
    # host-specific override
  })
];
```

### 2. Common overlay patterns

**Override package attributes:**

```nix
(final: prev: {
  myPackage = prev.myPackage.overrideAttrs (old: {
    version = "1.2.3";
    src = prev.fetchFromGitHub { ... };
  });
})
```

**Disable tests for a package (znver4 workaround pattern):**

```nix
(final: prev: {
  myPackage = prev.myPackage.overrideAttrs (old: {
    doCheck = false;
  });
})
```

**Apply an input's overlay:**

```nix
nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

## Gotchas

- `nixpkgs.overlays` is a list — multiple modules can each add overlays and they compose
- Overlay order matters for dependent overrides — overlays are applied left to right
- Use `final` (the fixed point, after all overlays) for dependencies and `prev` (before this overlay) for the package being overridden
- The CachyOS kernel overlay uses `inputs.nix-cachyos-kernel.overlays.pinned` — it's applied in `modules/kernel/cachyos.nix`, not in `flake.nix`
- For inline package overrides (one-off), prefer `overrideAttrs` directly in the module rather than a global overlay

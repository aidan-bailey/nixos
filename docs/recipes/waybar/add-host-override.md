# Add a Host-Specific Waybar Override

## When to use

When a Waybar module should only appear on one host, or when overriding a shared module's settings for a specific host.

## Files to modify

1. **Modify** `home/hosts/<host>.nix` — add or modify `custom.waybar.hostOverrides`

## Steps

### 1. Add the override

In the per-host home file, add to `custom.waybar.hostOverrides`:

**Adding a host-only module:**

```nix
custom.waybar.hostOverrides = {
  # Include it in modules-right (this REPLACES the base list)
  modules-right = [
    "tray"
    "cpu"
    "my-host-module"    # <-- new module
    "clock"
  ];

  # Define the module config
  "my-host-module" = {
    format = "{}";
    interval = 10;
  };
};
```

**Overriding a shared module's settings:**

```nix
custom.waybar.hostOverrides = {
  temperature.critical-threshold = 90;    # override just this field
};
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

## Gotchas

- `lib.recursiveUpdate` replaces lists entirely — if you override `modules-right`, you must include ALL modules you want, not just the new one
- Attrset values merge recursively — overriding `temperature.critical-threshold` doesn't remove other temperature settings
- Look at `home/hosts/nesco.nix` and `home/hosts/fresco.nix` for real examples

# Add a Shared Waybar Module

## When to use

When adding a Waybar module that should appear on all desktop hosts.

## Files to modify

1. **Modify** `home/modules/wayland.nix` — add the module definition to `waybarBase` and add the module name to a `modules-*` list

## Steps

### 1. Add module config to waybarBase

In the `waybarBase` attrset in `home/modules/wayland.nix`, add the module definition:

```nix
waybarBase = {
  # ... existing modules ...

  "my-module" = {
    format = "{usage}%";
    interval = 5;
    tooltip = true;
  };
};
```

### 2. Add to a modules list

Add the module name to `modules-left`, `modules-center`, or `modules-right` in `waybarBase`:

```nix
modules-right = [
  "tray"
  "my-module"    # <-- add here
  "clock"
];
```

**Note:** Per-host files override `modules-right` entirely — if you add a module to the shared base list, you must also add it to each host's override list, or hosts will lose it.

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
```

## Gotchas

- `modules-right` is typically overridden per-host — adding to the base list alone won't show the module on hosts that override the list
- Either add the module to all per-host `modules-right` lists, or only add it to the per-host lists (not the base)
- Module names with `/` (e.g., `sway/workspaces`) use the slash in the attrset key
- `lib.recursiveUpdate` merges recursively for attrsets but replaces lists entirely

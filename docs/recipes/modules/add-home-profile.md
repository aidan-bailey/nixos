# Add a Home Profile

## When to use

When you need a new role-based composition of home-manager modules (e.g., a "server" profile that imports a different set of modules than the desktop profile).

## Files to modify

1. **Create** `home/profiles/<name>.nix` — the new profile
2. **Modify** per-host home files — import the new profile instead of or alongside `desktop.nix`

## Steps

### 1. Create the profile

Profiles are import-only files with no config. They compose modules:

```nix
{ ... }:
{
  imports = [
    ../modules/module-a.nix
    ../modules/module-b.nix
  ];
}
```

### 2. Import from per-host home files

In `home/hosts/<host>.nix`:

```nix
{
  imports = [ ../profiles/<name>.nix ];

  # host-specific overrides here
}
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

## Gotchas

- Profiles should NOT contain config — only imports
- Currently only `desktop.nix` exists; per-host files (`home/hosts/nesco.nix`, `home/hosts/fresco.nix`) import it
- medesco has no per-host home file because it uses `serverModules` (no desktop profile)
- If a module is needed by ALL hosts regardless of profile, it belongs in `home/users/aidanb/default.nix`, not in a profile

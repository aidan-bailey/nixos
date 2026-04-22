# Add a System Module

## When to use

When you need a new system-level NixOS module that configures hardware, services, or system packages.

## Files to modify

1. **Create** `modules/<name>.nix` — the new module
2. **Modify** `flake.nix` — add the module to the appropriate profile (`serverModules` or `desktopModules`)

## Steps

### 1. Create the module file

Follow the standard module pattern. Use a `let` block for package lists:

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  myPackages = with pkgs; [
    # packages here
  ];
in
{
  environment.systemPackages = myPackages;

  # services, boot params, etc.
}
```

### 2. Add to a profile in flake.nix

Add the module path to `serverModules` (all hosts) or `desktopModules` (desktop/laptop only):

```nix
# In flake.nix, inside the let block:
serverModules = commonModules ++ [
  ./modules/base.nix
  # ... existing modules ...
  ./modules/<name>.nix    # <-- add here
];
```

If the module should only apply to desktop hosts, add it to `desktopModules` instead.

### 3. If the module needs conditional behavior

Use existing custom options from `modules/profile.nix`:

```nix
{
  config = lib.mkIf config.custom.features.gaming {
    # only applied when gaming is enabled
  };
}
```

Or create a new custom option (see [Add a custom option](add-custom-option.md)).

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

All three hosts must build successfully. If the module is only in `desktopModules`, medesco won't include it but should still build.

## Gotchas

- System modules receive `inputs` and `system` via `specialArgs` — include them in the function signature if needed
- The module path in `flake.nix` must start with `./modules/`
- If adding packages that need unfree licenses, check that `nixpkgs.config.allowUnfree = true` is set (it is, in `commonModules`)
- Use `lib.mkDefault` for values that device modules or host configs might want to override

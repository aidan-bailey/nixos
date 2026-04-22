# Add a Home-Manager Module

## When to use

When you need a new user-level module that configures programs, dotfiles, shell settings, or user services.

## Files to modify

1. **Create** `home/modules/<name>.nix` — the new module
2. **Modify** one of:
   - `home/users/aidanb/default.nix` — if the module applies to all hosts (base modules)
   - `home/profiles/desktop.nix` — if the module only applies to desktop hosts

## Steps

### 1. Create the module file

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
  home.packages = myPackages;

  # programs.<name>.enable = true;
  # xdg.configFile."<app>/config".source = ...;
}
```

### 2. Import the module

**For all hosts** — add to `home/users/aidanb/default.nix` imports:

```nix
imports = [
  ../../modules/shell.nix
  # ... existing imports ...
  ../../modules/<name>.nix    # <-- add here
];
```

Note: paths are relative from `home/users/aidanb/` to `home/modules/`.

**For desktop hosts only** — add to `home/profiles/desktop.nix`:

```nix
imports = [
  ../modules/wayland.nix
  # ... existing imports ...
  ../modules/<name>.nix    # <-- add here
];
```

Note: paths are relative from `home/profiles/` to `home/modules/`.

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
```

If added to `default.nix` (all hosts), also verify:
```bash
nixos-rebuild build --flake .#medesco
```

## Gotchas

- Home modules use `home.packages` not `environment.systemPackages`
- Home modules use `extraSpecialArgs` (not `specialArgs`) — same names (`inputs`, `system`) but different mechanism
- The import path differs depending on where you import from: `../../modules/` from `users/aidanb/`, `../modules/` from `profiles/`
- Do NOT import desktop-only modules (wayland, gaming) from `default.nix` — they belong in `profiles/desktop.nix`
- If the module defines custom options, they must be under a namespace (e.g., `custom.<feature>`)

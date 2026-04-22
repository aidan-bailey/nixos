# Add a Host

## When to use

When setting up a new machine that will use this NixOS configuration.

## Files to modify

1. **Create** `hosts/<name>/configuration.nix` — host entry point
2. **Create** `hosts/<name>/hardware-configuration.nix` — generated on the target machine
3. **Optionally create** `home/hosts/<name>.nix` — per-host home-manager overrides (desktop hosts only)
4. **Optionally create** `modules/devices/<name>.nix` — hardware-specific module
5. **Modify** `flake.nix` — add the host to `nixosConfigurations`

## Steps

### 1. Generate hardware-configuration.nix on the target machine

```bash
sudo nixos-generate-config --show-hardware-config > hosts/<name>/hardware-configuration.nix
```

### 2. Create configuration.nix

Use an existing host as a template. Minimal desktop host:

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
    ./hardware-configuration.nix
    ../../modules/devices/<name>.nix    # if you have a device module
  ];

  custom.hostType = "desktop";           # "laptop", "desktop", or "server"
  custom.display.type = "lcd";           # "oled" or "lcd"

  networking.hostName = "<name>";

  home-manager.users.aidanb.imports = [ ../../home/hosts/<name>.nix ];
}
```

Minimal server host (no device module, no home overrides):

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
    ./hardware-configuration.nix
  ];

  networking.hostName = "<name>";
}
```

### 3. Create per-host home overrides (desktop hosts)

See [Add host home overrides](add-host-home-overrides.md).

### 4. Add to flake.nix

Add to the `nixosConfigurations` attrset:

```nix
nixosConfigurations = {
  nesco = mkHost { ... };
  fresco = mkHost { ... };
  medesco = mkHost { ... };
  <name> = mkHost {
    hostConfig = ./hosts/<name>/configuration.nix;
    profile = desktopModules;    # or serverModules
  };
};
```

### 5. Create a README (optional)

```bash
touch hosts/<name>/README.md
```

Document the hardware specs and any known issues.

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- `hardware-configuration.nix` must be generated on the actual target hardware — do not copy from another host
- The `networking.hostName` should match the flake attribute name
- Server hosts use `serverModules`, desktop/laptop hosts use `desktopModules`
- If adding a device module, it must be imported from `configuration.nix`, NOT added to profiles in `flake.nix`
- If the host uses distributed builds, pin the remote host's SSH key in `configuration.nix` (see nesco for example)

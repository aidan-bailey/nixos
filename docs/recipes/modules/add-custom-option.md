# Add a Custom Option

## When to use

When you need a new option that controls conditional behavior across multiple modules (e.g., enabling/disabling a feature set, or configuring a hardware property).

## Files to modify

1. **Modify** `modules/profile.nix` — define the new option
2. **Modify** device modules or host configs — set the option value
3. **Modify** consuming modules — use the option with `lib.mkIf` or direct access

## Steps

### 1. Add the option definition to profile.nix

Options live under `options.custom`. Follow the existing pattern:

**For a boolean feature flag:**

```nix
options.custom.features.myFeature = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable my feature set";
};
```

**For an enum:**

```nix
options.custom.myProperty = lib.mkOption {
  type = lib.types.enum [
    "optionA"
    "optionB"
  ];
  description = "Select the property type";
};
```

**For a nullable option (optional):**

```nix
options.custom.myProperty = lib.mkOption {
  type = lib.types.nullOr (lib.types.enum [
    "optionA"
    "optionB"
  ]);
  default = null;
  description = "Optional property";
};
```

### 2. Set the value in device modules or host configs

In a device module (e.g., `modules/devices/zenbook_s16.nix`):

```nix
custom.myProperty = "optionA";
```

Or in a host config (e.g., `hosts/nesco/configuration.nix`):

```nix
custom.features.myFeature = false;
```

### 3. Consume the option in modules

```nix
config = lib.mkIf config.custom.features.myFeature {
  # conditional config
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

## Gotchas

- `profile.nix` has NO config block — it only defines options
- All options must be under `options.custom` to avoid conflicts with NixOS options
- Non-nullable options without defaults must be set by every host that includes the module — prefer defaults or nullable types
- Boolean defaults should match the common case (e.g., `default = true` if most hosts want it)

# Add a Custom Waybar Script

## When to use

When adding a Waybar module that runs a shell script (e.g., monitoring, API calls, system queries).

## Files to modify

1. **Create** `config/waybar/scripts/<name>.sh` — the shell script
2. **Modify** `home/modules/wayland.nix` — wrap the script as a package and add the module config
3. **Modify** per-host files — add the module to `modules-right` if host-specific

## Steps

### 1. Write the shell script

Create `config/waybar/scripts/<name>.sh`:

```bash
#!/usr/bin/env bash
# Output JSON for Waybar
value=$(some-command)
echo "{\"text\": \"$value\", \"tooltip\": \"Details: $value\"}"
```

Waybar custom modules expect either plain text or JSON with `text`, `tooltip`, `class` fields.

### 2. Wrap as a package in wayland.nix

In the `home.packages` list in `home/modules/wayland.nix`, add:

```nix
(pkgs.writeShellScriptBin "waybar-<name>"
  (builtins.readFile ../../config/waybar/scripts/<name>.sh))
```

### 3. Add the module config

In `waybarBase` (if shared) or `custom.waybar.hostOverrides` (if host-specific):

```nix
"custom/<name>" = {
  exec = "waybar-<name>";
  return-type = "json";
  interval = 30;
  format = "{}";
};
```

### 4. Add to modules list

Add `"custom/<name>"` to `modules-right` in the appropriate location.

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying, test the script standalone:
```bash
waybar-<name>
```

## Gotchas

- Script files in `config/waybar/scripts/` are read at build time via `builtins.readFile` — changes require a rebuild
- The script name becomes the executable name (e.g., `waybar-weather` → `exec = "waybar-weather"`)
- Scripts should output valid JSON if using `return-type = "json"`
- Runtime dependencies (e.g., `nvidia-smi`, `amdgpu_top`) must be available on PATH — if needed, use `writeShellApplication` with `runtimeInputs` instead of `writeShellScriptBin`
- Add styling for the new module in `config/waybar/style.css` using `#custom-<name>` selector

# Add a Kernel Workaround

## When to use

When you need to work around a hardware or firmware bug using kernel parameters, module options, or boot configuration.

## Files to modify

1. **Modify** `modules/devices/<device>.nix` — add kernel params or module config

## Steps

### 1. Identify the workaround type

**Kernel boot parameters** — most common:

```nix
boot.kernelParams = [
  "amdgpu.dcdebugmask=0x600"     # disable PSR (panel self-refresh)
  "amdgpu.abmlevel=0"            # disable adaptive backlight
];
```

**Kernel module options** — for driver-level settings:

```nix
boot.extraModprobeConfig = ''
  options mt7921e power_save=0
'';
```

**initrd kernel modules** — for early driver loading:

```nix
boot.initrd.kernelModules = [ "amdgpu" ];
```

### 2. Add to the device module

Group workarounds together with comments documenting each bug:

```nix
# Strix Point AMDGPU workarounds
boot.kernelParams = [
  "amdgpu.dcdebugmask=0x600"              # disable PSR — causes flickering
  "amdgpu.sg_display=0"                    # scatter-gather display — causes flashing
  "amdgpu.ip_block_mask=0xffffbfff"        # disable VPE — broken s2idle resume
];
```

## Verification

```bash
nixos-rebuild build --flake .#<host>
```

After deploying, verify the parameter took effect:

```bash
cat /proc/cmdline    # check kernel params
```

## Gotchas

- Always comment workarounds with what bug they fix — future you (or future LLM) needs to know when it's safe to remove
- Kernel params in `boot.kernelParams` are appended, not replaced — multiple modules can add params
- If a workaround is needed by multiple devices, consider putting it in a shared module under `modules/` rather than duplicating
- Track workarounds in the host's README.md (see `hosts/fresco/README.md` for the znver4 tracking table pattern)

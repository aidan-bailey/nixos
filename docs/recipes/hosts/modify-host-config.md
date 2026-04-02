# Modify Host Config

## When to use

When changing settings that are specific to a single host — boot parameters, distributed builds, SSH host keys, custom options.

## Files to modify

1. **Modify** `hosts/<name>/configuration.nix` — for system-level host settings
2. **Optionally modify** `home/hosts/<name>.nix` — for user-level host settings

## Steps

### 1. Identify what to change

Host configs handle settings that differ per machine:
- `custom.hostType` and `custom.display.type`
- Boot parameters (`boot.resumeDevice`, kernel params)
- Distributed build configuration
- SSH known hosts
- The `home-manager.users.aidanb.imports` line

Everything else should go in modules (system or device), not host configs.

### 2. Make the change

Host configs are standard NixOS configuration. Example — adding a kernel parameter:

```nix
boot.kernelParams = [ "my_param=value" ];
```

Example — adding a distributed build target:

```nix
nix.distributedBuilds = true;
nix.buildMachines = [{
  hostName = "remote-host";
  sshUser = "nixremote";
  protocol = "ssh-ng";
  systems = [ "x86_64-linux" ];
  maxJobs = 4;
  speedFactor = 2;
  supportedFeatures = [ "big-parallel" "kvm" ];
}];
```

## Verification

```bash
nixos-rebuild build --flake .#<name>
```

## Gotchas

- Host config has higher priority than profile modules (it's first in the `mkHost` module list)
- Hardware-specific settings belong in device modules, not host configs
- Settings that apply to multiple hosts belong in shared modules, not duplicated in host configs

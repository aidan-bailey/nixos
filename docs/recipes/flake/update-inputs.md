# Update Flake Inputs

## When to use

When updating external dependencies to newer versions.

## Files to modify

1. **Modify** `flake.lock` — via `nix flake update` commands

## Steps

### Update all inputs

```bash
nix flake update
```

### Update a single input

```bash
nix flake update nixpkgs
nix flake update home-manager
```

### Pin an input to a specific revision

```bash
nix flake update my-input --override-input my-input github:owner/repo/<rev>
```

## Verification

```bash
nix flake check
nixos-rebuild build --flake .#nesco
nixos-rebuild build --flake .#fresco
nixos-rebuild build --flake .#medesco
```

Build all three hosts — input updates can break any of them.

## Gotchas

- nix-cachyos-kernel has its own nixpkgs pin — updating nixpkgs does NOT update the kernel's nixpkgs
- After `nix flake update`, always build all three hosts before switching — breakage is common
- The lock file can be large diffs — review `git diff flake.lock` to see what changed
- If a specific input update breaks a build, you can revert just that input: `nix flake update <input> --override-input <input> github:owner/repo/<old-rev>`

# Add a Flake Input

## When to use

When adding a new external dependency — a NixOS module, package set, overlay, or tool that comes from another flake.

## Files to modify

1. **Modify** `flake.nix` — add the input and wire it into outputs
2. **Run** `nix flake lock` — update the lock file

## Steps

### 1. Add the input

In the `inputs` block of `flake.nix`:

```nix
inputs = {
  # ... existing inputs ...

  my-input = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";    # unless it needs its own nixpkgs
  };
};
```

### 2. Add to the outputs function signature

```nix
outputs = {
  nixpkgs,
  home-manager,
  # ... existing inputs ...
  my-input,
  ...
}:
```

### 3. Wire it in

**As a NixOS module** — add to the appropriate profile:

```nix
serverModules = commonModules ++ [
  my-input.nixosModules.default
  # ...
];
```

**As a package** — reference in a module:

```nix
home.packages = [
  inputs.my-input.packages.${system}.default
];
```

**As an overlay** — add to commonModules or a specific module:

```nix
nixpkgs.overlays = [ my-input.overlays.default ];
```

### 4. Update the lock file

```bash
nix flake lock
```

## Verification

```bash
nix flake check
nixos-rebuild build --flake .#nesco
```

## Gotchas

- Use `inputs.nixpkgs.follows = "nixpkgs"` unless the input needs its own nixpkgs (like nix-cachyos-kernel)
- The input name in `inputs = { ... }` must match the parameter name in `outputs = { ... }`
- `inputs` is available in system modules via `specialArgs` and in home modules via `extraSpecialArgs`
- Local flake inputs use `url = "path:./flakes/my-input"` (see `doom-flake`)
- After adding, run `nix flake lock` to generate the lock entry

# Add a User Secret

## When to use

When a user program or home-manager module needs access to an encrypted secret (OAuth tokens, API keys, etc.).

## Files to modify

1. **Modify** `secrets/home.yaml` — add the secret value (via `sops`)
2. **Modify** `home/modules/secrets.nix` or the consuming home module — declare and use the secret

## Steps

### 1. Add the secret to home.yaml

```bash
sops secrets/home.yaml
```

Add the new key:

```yaml
my_token: "the-actual-secret-value"
```

### 2. Declare the secret in a home module

```nix
sops.secrets.my_token = {
  # sopsFile is inherited from home/modules/secrets.nix defaultSopsFile
};
```

### 3. Reference the secret path

For environment variables (common pattern — see claude.nix OAuth token):

```nix
programs.zsh.envExtra = ''
  export MY_TOKEN="$(cat ${config.sops.secrets.my_token.path})"
'';
```

For config files:

```nix
home.file.".config/app/config".text = ''
  token_file = ${config.sops.secrets.my_token.path}
'';
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
cat $(cat /run/user/$(id -u)/secrets/my_token)    # verify decryption
```

## Gotchas

- User secrets use `secrets/home.yaml`, NOT `secrets/secrets.yaml`
- The user age key is at `~/.config/sops/age/keys.txt`, not the system key
- User secret paths are under `/run/user/<uid>/secrets/`, not `/run/secrets/`
- Reading secrets via `$(cat ...)` in shell envExtra works but happens at shell startup — if the secret changes, you need a new shell
- sops-nix for home-manager is loaded via `sharedModules` in `flake.nix` commonModules

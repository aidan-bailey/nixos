# Add a System Secret

## When to use

When a NixOS service or system module needs access to an encrypted secret (API key, password, certificate, etc.).

## Files to modify

1. **Modify** `secrets/secrets.yaml` — add the secret value (via `sops`)
2. **Modify** the consuming module — declare and use the secret

## Steps

### 1. Add the secret to secrets.yaml

```bash
sops secrets/secrets.yaml
```

This opens the decrypted file in your editor. Add the new key:

```yaml
my_api_key: "the-actual-secret-value"
```

Save and close — sops re-encrypts automatically.

### 2. Declare the secret in the consuming module

```nix
sops.secrets.my_api_key = {
  # optional overrides:
  # owner = "someuser";
  # group = "somegroup";
  # mode = "0440";
};
```

### 3. Reference the secret path

```nix
services.myservice.apiKeyFile = config.sops.secrets.my_api_key.path;
```

The path defaults to `/run/secrets/my_api_key`.

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
sudo cat /run/secrets/my_api_key    # verify decryption
```

## Gotchas

- Secrets are files, not environment variables — services must support reading from a file path
- The `defaultSopsFile` is `secrets/secrets.yaml` — you don't need to specify `sopsFile` unless using a different file
- If adding a host-specific secret file, add a creation rule to `.sops.yaml` first
- Secret files in `/run/secrets/` are only readable by root by default — set `owner`/`mode` if a non-root service needs access
- The age key must exist on the target machine at `/var/lib/sops-nix/key.txt` before deployment

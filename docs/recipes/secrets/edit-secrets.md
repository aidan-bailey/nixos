# Edit Secrets

## When to use

When you need to change the value of an existing encrypted secret.

## Files to modify

1. **Modify** `secrets/secrets.yaml` or `secrets/home.yaml` — via `sops`

## Steps

### 1. Open the encrypted file

```bash
sops secrets/secrets.yaml    # system secrets
sops secrets/home.yaml       # user secrets
```

### 2. Edit the value

The file opens decrypted in your editor. Change the value, save, and close. Sops re-encrypts automatically.

### 3. Rebuild

```bash
sudo nixos-rebuild switch --flake .#<host>
```

The new secret value is decrypted at activation time.

## Verification

After switching:
```bash
sudo cat /run/secrets/<secret_name>    # system secrets
```

## Gotchas

- You must have the age key on the machine where you run `sops` — it won't work without the decryption key
- After editing, the file will have new encrypted values in git — commit the change
- Do NOT edit the encrypted YAML directly — always use `sops` to open it
- If you need to add a new key to `.sops.yaml` (e.g., a new host), run `sops updatekeys secrets/secrets.yaml` after updating `.sops.yaml`

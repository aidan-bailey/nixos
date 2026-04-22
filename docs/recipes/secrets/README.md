# Secrets

## Overview

Read this when working with encrypted secrets. This repo uses sops-nix with age encryption for both system-level and user-level secrets.

## Design

### Two Secret Scopes

**System secrets** — owned by root, available to NixOS services:
- File: `secrets/secrets.yaml`
- Key: `/var/lib/sops-nix/key.txt`
- Config: `modules/secrets.nix`
- Access: `config.sops.secrets.<name>`

**User secrets** — owned by the user, available in home-manager:
- File: `secrets/home.yaml`
- Key: `~/.config/sops/age/keys.txt`
- Config: `home/modules/secrets.nix`
- Access: `config.sops.secrets.<name>` (home-manager context)

### Key Management

Keys are defined in `.sops.yaml` with age key anchors. Each host has its own age key. Creation rules control which keys can decrypt which files:

- `secrets/secrets.yaml` → encrypted to both nesco and fresco keys
- `secrets/home.yaml` → encrypted to both keys
- `secrets/nesco.yaml` → encrypted to nesco key only (host-specific secrets)

### How Secrets Are Used

Secrets are decrypted at activation time and placed at a path (default: `/run/secrets/<name>` for system, `/run/user/<uid>/secrets/<name>` for user). Modules reference the path, not the value.

## Key Files

| File | Role |
|------|------|
| `.sops.yaml` | Key configuration and creation rules |
| `secrets/secrets.yaml` | Encrypted system secrets |
| `secrets/home.yaml` | Encrypted user secrets |
| `modules/secrets.nix` | System sops-nix config |
| `home/modules/secrets.nix` | User sops-nix config |

## Recipes

- [Add a system secret](add-system-secret.md) — Add a new system-level encrypted secret
- [Add a user secret](add-user-secret.md) — Add a new user-level encrypted secret
- [Edit secrets](edit-secrets.md) — Modify existing encrypted secret values

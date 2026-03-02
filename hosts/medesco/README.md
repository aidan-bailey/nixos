# medesco

Lightweight media server — headless base with networking and Nixarr.

## Profile

**serverModules** — base system, user account, networking, terminal, media server, and secrets. No desktop, audio, gaming, or virtualisation.

## Services

Inherits from `modules/mediaserver.nix`:

- Jellyfin (media streaming)
- Transmission (downloads)
- Sonarr, Radarr, Lidarr, Readarr (media management)
- Prowlarr (indexer)
- Bazarr (subtitles)
- Jellyseerr (requests)

## Setup

The `hardware-configuration.nix` is a placeholder — regenerate it with `nixos-generate-config` on the target machine before first build.

## Build

```bash
sudo nixos-rebuild switch --flake .#medesco
```

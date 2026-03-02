# Aidan's NixOS System Configuration

A modular NixOS configuration for AMD Zen 5 systems with optimizations for performance, development, and gaming.

## Hosts

- **nesco** — Primary laptop (ASUS Zenbook S16), full desktop with Sway, gaming, virtualisation, media server
- **fresco** — Secondary system, same stack without device-specific tweaks
- **medesco** — Lightweight server (base, networking, terminal, media server)

## System Structure

```
.
├── flake.nix                # Main flake configuration
├── init.sh                  # Post-installation setup script
├── .sops.yaml               # Secrets management rules
├── hosts/
│   ├── nesco/               # ASUS Zenbook S16 laptop
│   ├── fresco/              # Secondary system
│   └── medesco/             # Media server
├── modules/                 # System-level NixOS modules
│   ├── amd/
│   │   ├── cpu.nix          # AMD CPU microcode + amd_pstate
│   │   ├── graphics.nix     # AMDGPU driver, Mesa, VA-API
│   │   └── zen5.nix         # Zen 5 compiler/kernel optimizations
│   ├── devices/
│   │   └── zenbook_s16.nix  # Zenbook-specific config (HDR, asusd)
│   ├── kernel/
│   │   └── cachyos.nix      # CachyOS kernel
│   ├── nvidia/
│   │   └── graphics.nix     # NVIDIA driver config
│   ├── audio.nix            # PipeWire audio + Bluetooth codecs
│   ├── base.nix             # Base system (packages, zram, tmpfs, printing)
│   ├── bluetooth.nix        # Bluetooth support + blueman
│   ├── gaming.nix           # Steam + Proton-GE
│   ├── mediaserver.nix      # Nixarr media stack
│   ├── networking.nix       # NetworkManager, encrypted DNS, nftables, SSH, mDNS
│   ├── nix-ld.nix           # Dynamic library compatibility
│   ├── power.nix            # TLP power management
│   ├── secrets.nix          # SOPS-nix encrypted secrets
│   ├── sway.nix             # Sway window manager (system-level)
│   ├── terminal.nix         # System shell setup
│   ├── user.nix             # User account configuration
│   └── virtualisation.nix   # Docker, libvirtd, QEMU/KVM
├── home/                    # Home-manager modules (user-level)
│   ├── users/
│   │   └── aidanb/          # User config entry point
│   └── modules/
│       ├── apps.nix         # User applications
│       ├── development.nix  # Direnv + nix-direnv
│       ├── devtools.nix     # Dev tools + Zed editor config
│       ├── editor.nix       # Neovim
│       ├── gaming.nix       # Gaming applications
│       ├── git.nix          # Git configuration
│       ├── research.nix     # TeX, Zotero, Typst
│       ├── secrets.nix      # SOPS-nix user secrets
│       ├── shell.nix        # Zsh + oh-my-zsh
│       ├── terminal.nix     # Alacritty
│       └── wayland.nix      # Sway/Waybar user config + tools
├── config/                  # Static config files
│   ├── sway/                # Sway config + wallpaper
│   └── waybar/              # Waybar config + CSS
├── secrets/                 # Encrypted secrets (age/sops-nix)
│   ├── secrets.yaml         # System secrets
│   └── home.yaml            # User secrets
└── flakes/
    ├── doom-emacs/          # Doom Emacs flake (PGTK + native-comp)
    ├── ccache/              # Reusable ccache NixOS module
    └── gcc-lto-pgo/         # Custom GCC 13 with LTO + PGO
```

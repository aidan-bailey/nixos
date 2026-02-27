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
├── hosts/
│   ├── nesco/               # ASUS Zenbook S16 laptop
│   ├── fresco/              # Secondary system
│   └── medesco/             # Media server
├── modules/                 # System-level NixOS modules
│   ├── amd/
│   │   ├── cpu.nix          # AMD CPU settings
│   │   ├── graphics.nix     # AMDGPU driver
│   │   └── zen5.nix         # Zen 5 compiler/kernel optimizations
│   ├── devices/
│   │   └── zenbook_s16.nix  # Zenbook-specific config
│   ├── kernel/
│   │   └── cachyos.nix      # CachyOS kernel
│   ├── audio.nix            # PipeWire audio
│   ├── base.nix             # Base system configuration
│   ├── bluetooth.nix        # Bluetooth support
│   ├── gaming.nix           # Steam + Proton
│   ├── mediaserver.nix      # Nixarr media stack
│   ├── networking.nix       # NetworkManager, SSH, Samba
│   ├── nix-ld.nix           # Dynamic library compatibility
│   ├── power.nix            # TLP power management
│   ├── sway.nix             # Sway window manager (system-level)
│   ├── terminal.nix         # System shell setup
│   ├── user.nix             # User account configuration
│   └── virtualisation.nix   # Docker, libvirtd, QEMU/KVM
├── home/                    # Home-manager modules (user-level)
│   ├── users/
│   │   └── aidanb/          # User config entry point
│   └── modules/
│       ├── apps.nix         # User applications
│       ├── development.nix  # Direnv
│       ├── devtools.nix     # Dev tools + Zed editor config
│       ├── editor.nix       # Neovim
│       ├── gaming.nix       # Gaming applications
│       ├── git.nix          # Git configuration
│       ├── research.nix     # TeX, Zotero, Typst
│       ├── shell.nix        # Zsh + oh-my-zsh
│       ├── terminal.nix     # Alacritty
│       └── wayland.nix      # Sway/Waybar user config + tools
├── config/                  # Static config files
│   ├── sway/                # Sway config + wallpaper
│   └── waybar/              # Waybar config + CSS
└── flakes/
    └── doom-emacs/          # Doom Emacs flake (PGTK + native-comp)
```

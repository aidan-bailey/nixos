# Aidan's NixOS System Configuration

A modular NixOS configuration for AMD Zen 5 systems with optimizations for performance, development, and gaming.

## System Structure

```
.
├── flake.nix              # Main flake configuration
├── hosts/
│   └── nesco/             # Host-specific configuration
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── amd/               # AMD-specific modules
│   │   ├── cpu.nix        # General AMD CPU settings
│   │   ├── graphics.nix   # AMD GPU configuration
│   │   └── zen5.nix       # Zen 5 optimizations
│   ├── kernel/
│   │   └── cachyos.nix    # CachyOS kernel configuration
│   ├── apps.nix           # Application packages
│   ├── audio.nix          # Audio (PipeWire) setup
│   ├── base.nix           # Base system configuration
│   ├── bluetooth.nix      # Bluetooth support
│   ├── devtools.nix       # Development environment
│   ├── gaming.nix         # Gaming setup
│   ├── networking.nix     # Network configuration
│   ├── sway.nix           # Sway window manager
│   ├── terminal.nix       # Terminal emulator setup
│   ├── user.nix           # User account configuration
│   ├── virtualisation.nix # VM and container setup
│   └── zenbook_s16/       # Device-specific optimizations
│       └── power.nix
├── configs/               # Configuration files
│   ├── doom.d/           # Doom Emacs configuration
│   └── zshrc             # Zsh configuration
└── flakes/
    └── doom-emacs/        # Doom Emacs flake
```

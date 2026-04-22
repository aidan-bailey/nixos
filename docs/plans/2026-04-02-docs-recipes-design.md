# Design: `docs/recipes/` — LLM Modification Guides

## Problem

CLAUDE.md provides architectural overview but lacks actionable "how to modify X" guidance. LLMs working on this repo need concrete steps, file lists, and gotchas to make correct changes.

## Solution

A `docs/recipes/` directory with nested topic directories. Each topic has a `README.md` (reference + recipe index) and granular recipe files (one per task). CLAUDE.md links to all topics via a dedicated `## Recipes` table.

## Directory Structure

```
docs/recipes/
├── modules/
│   ├── README.md                    # Reference: two-layer system, custom options, module composition
│   ├── add-system-module.md
│   ├── add-home-module.md
│   ├── add-custom-option.md
│   └── add-home-profile.md
├── hosts/
│   ├── README.md                    # Reference: mkHost helper, host/profile relationship, per-host integration
│   ├── add-host.md
│   ├── modify-host-config.md
│   └── add-host-home-overrides.md
├── devices/
│   ├── README.md                    # Reference: CPU/GPU hierarchy, device module contracts
│   ├── add-device-module.md
│   ├── add-kernel-workaround.md
│   └── add-gpu-support.md
├── secrets/
│   ├── README.md                    # Reference: sops-nix, age encryption, system vs user secrets
│   ├── add-system-secret.md
│   ├── add-user-secret.md
│   └── edit-secrets.md
├── waybar/
│   ├── README.md                    # Reference: Nix-generated base, recursive update, script pattern
│   ├── add-shared-module.md
│   ├── add-host-override.md
│   └── add-custom-script.md
├── flake/
│   ├── README.md                    # Reference: inputs, overlays, mkHost, module profiles
│   ├── add-flake-input.md
│   ├── add-overlay.md
│   └── update-inputs.md
├── kernel/
│   ├── README.md                    # Reference: CachyOS kernel, LTO variants, binary cache
│   ├── change-kernel-variant.md
│   └── add-kernel-patch.md
└── claude/
    ├── README.md                    # Reference: claude.nix, settings, hooks, MCP, squad
    ├── modify-claude-settings.md
    ├── add-hook.md
    └── add-mcp-server.md
```

8 topics, 8 READMEs, ~27 recipe files.

## README.md Format (per topic)

```markdown
# <Topic>

## Overview
Brief description of what this area covers and when an LLM should read this.

## Design
How it works — architecture, data flow, key files, contracts.

## Key Files
Table of files involved with one-line descriptions.

## Recipes
- [Add X](add-x.md) — one-line description
- [Modify Y](modify-y.md) — one-line description
```

## Recipe File Format

```markdown
# <Verb> <Thing>

## When to use
One sentence on when this recipe applies.

## Files to modify
Ordered list of files that need changes, with why.

## Steps
Numbered steps with code examples pulled from real existing patterns in the repo.

## Verification
How to confirm the change works (build commands, test commands).

## Gotchas
Common mistakes or non-obvious constraints.
```

## CLAUDE.md Integration

Add a `## Recipes` section after the existing `### Patterns` section:

```markdown
## Recipes

Detailed modification guides live in `docs/recipes/`. Read the relevant recipe before making changes.

| Topic | When to read | Path |
|-------|-------------|------|
| Modules | Adding or modifying system/home-manager modules | `docs/recipes/modules/` |
| Hosts | Adding a host or changing host-specific config | `docs/recipes/hosts/` |
| Devices | Adding hardware support, CPU/GPU layers, workarounds | `docs/recipes/devices/` |
| Secrets | Working with sops-nix encrypted secrets | `docs/recipes/secrets/` |
| Waybar | Modifying status bar modules or scripts | `docs/recipes/waybar/` |
| Flake | Changing inputs, overlays, or the mkHost helper | `docs/recipes/flake/` |
| Kernel | Kernel variants, patches, CachyOS config | `docs/recipes/kernel/` |
| Claude | Claude Code settings, hooks, MCP servers | `docs/recipes/claude/` |
```

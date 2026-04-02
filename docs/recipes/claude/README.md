# Claude

## Overview

Read this when modifying Claude Code configuration — settings, hooks, MCP servers, or supporting tools. All Claude Code config is Nix-generated and deployed as read-only store symlinks.

## Design

### Declarative Settings

`~/.claude/settings.json` is generated from a `claudeSettings` attrset in `home/modules/claude.nix`. It includes:
- Model preference (`opus`)
- Hooks (notification hooks, conditionally generated)
- Enabled plugins
- Sandbox rules (network allowlist, filesystem deny)
- Effort level
- Status line config

The file is a read-only nix store symlink — you cannot edit it manually. All changes must go through `claude.nix`.

### Notification Hooks

Hooks are conditionally generated based on `custom.claude.notifications` options:
- Three channels: desktop, push, popup
- Two event types: Stop, Notification
- Hook script: `config/claude/hooks/notify.sh`
- Config file: generated `notify.conf` with channel enable flags

Currently **disabled** in `home/users/aidanb/default.nix`.

### Supporting Tools

| Tool | Source | Role |
|------|--------|------|
| claude-code-nix | flake input | Claude Code CLI |
| claude-squad | flake input, wrapped | Multi-session manager |
| tail-claude | buildGoModule | Session log viewer |
| mcp-nixos | flake input | NixOS MCP server |

### Environment Variables

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "true"` — enables agent teams
- `CLAUDE_CODE_EFFORT_LEVEL = "max"` — overrides the `effortLevel` in settings
- `CLAUDE_CODE_OAUTH_TOKEN` — from sops-nix encrypted secret

## Key Files

| File | Role |
|------|------|
| `home/modules/claude.nix` | Main config: settings, hooks, tools, secrets |
| `config/claude/hooks/notify.sh` | Notification hook script |
| `config/claude/statusline.sh` | Status line script |
| `home/users/aidanb/default.nix` | Notification enable/disable |
| `.mcp.json` | MCP server config (repo-level) |

## Recipes

- [Modify Claude settings](modify-claude-settings.md) — Change settings.json via the Nix attrset
- [Add a hook](add-hook.md) — Add a new Claude Code hook
- [Add an MCP server](add-mcp-server.md) — Add a new MCP server

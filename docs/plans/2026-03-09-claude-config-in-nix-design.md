# Claude Code Configuration in Nix

## Goal

Make `~/.claude/settings.json` and `~/.claude/statusline.sh` declaratively managed by Nix, eliminating config drift and making the Claude Code setup fully reproducible.

## What We're Managing

### settings.json (Nix-generated JSON)

Generated from a Nix attrset via `builtins.toJSON`. Contains:

- **model**: `"opus"` — default model
- **hooks**: Notification and Stop event handlers pointing to `~/.claude/hooks/notify.sh`
- **enabledPlugins**: Map of 9 plugins (superpowers, feature-dev, semgrep, LSPs, etc.)
- **sandbox**: Auto-allow bash, allowed network domains, filesystem deny rules
- **effortLevel**: `"high"`
- **statusLine**: Command hook pointing to `~/.claude/statusline.sh`

### statusline.sh (deployed script)

Custom two-line status bar script. Moves from unmanaged `~/.claude/statusline.sh` to `config/claude/statusline.sh` in the repo, deployed via `home.file` with executable permissions.

### NOT managing

- `installed_plugins.json` — runtime-managed (install paths, timestamps, git SHAs)
- `projects/`, `teams/`, `tasks/` — runtime state
- `.credentials.json` — OAuth flow managed
- `skills/` — separate git repo

## Architecture

Both files are nix store symlinks (read-only). Claude Code cannot modify `settings.json` at runtime — all config changes go through the Nix source. This prevents drift and ensures reproducibility.

## Implementation

Extend `home/modules/claude.nix`:

1. Define `claudeSettings` attrset in the `let` block
2. Add `home.file.".claude/settings.json".text = builtins.toJSON claudeSettings`
3. Move `statusline.sh` to `config/claude/statusline.sh`
4. Add `home.file.".claude/statusline.sh"` deployment (same pattern as notify.sh)

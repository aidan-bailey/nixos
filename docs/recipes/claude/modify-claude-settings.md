# Modify Claude Settings

## When to use

When changing Claude Code settings — model, effort level, plugins, sandbox rules, or any other `settings.json` field.

## Files to modify

1. **Modify** `home/modules/claude.nix` — update the `claudeSettings` attrset

## Steps

### 1. Find the claudeSettings attrset

In `home/modules/claude.nix`, the `claudeSettings` attrset is in the `let` block. It maps directly to `~/.claude/settings.json`.

### 2. Make the change

**Change model:**

```nix
claudeSettings = {
  model = "sonnet";    # was "opus"
  # ...
};
```

**Add a sandbox rule:**

```nix
sandbox = {
  network = {
    allow = [
      "github.com"
      "new-domain.com"    # <-- add here
    ];
  };
  filesystem = {
    deny = [
      "~/.ssh"
      "/new/path"    # <-- add here
    ];
  };
};
```

**Enable/disable a plugin:**

```nix
enabledPlugins = {
  "plugin-name" = true;     # enable
  "other-plugin" = false;   # disable
};
```

**Change effort level:**

The effort level is set in TWO places:
- `claudeSettings.effortLevel = "high"` — in settings.json
- `CLAUDE_CODE_EFFORT_LEVEL = "max"` — env var in sessionVariables (overrides settings)

To change effective effort, modify the env var:

```nix
home.sessionVariables = {
  CLAUDE_CODE_EFFORT_LEVEL = "high";    # was "max"
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying, check the generated file:
```bash
cat ~/.claude/settings.json | jq .
```

## Gotchas

- `~/.claude/settings.json` is a read-only nix store symlink — you CANNOT edit it manually
- The `CLAUDE_CODE_EFFORT_LEVEL` env var overrides `effortLevel` in settings — check both
- The `hooks` field is conditionally generated from notification options — don't add hooks directly to `claudeSettings.hooks` (use the hook options instead, or see [Add a hook](add-hook.md))
- After rebuilding, you may need to restart Claude Code for settings to take effect

# Add a Hook

## When to use

When adding a new Claude Code hook — a script that runs in response to Claude Code events (Stop, Notification, etc.).

## Files to modify

1. **Create** `config/claude/hooks/<name>.sh` — the hook script
2. **Modify** `home/modules/claude.nix` — add the hook to `claudeSettings.hooks` or the notification system

## Steps

### 1. Write the hook script

Create `config/claude/hooks/<name>.sh`:

```bash
#!/usr/bin/env bash
# Hook receives event data via environment variables
# See Claude Code docs for available variables
```

### 2. Deploy the script via home.file

In `home/modules/claude.nix`, add to the config block:

```nix
home.file.".claude/hooks/<name>.sh" = {
  source = ../../config/claude/hooks/<name>.sh;
  executable = true;
};
```

### 3. Add to claudeSettings.hooks

For notification-style hooks, use the existing `custom.claude.notifications` options.

For other hooks, add directly to the hooks in the `claudeSettings` attrset:

```nix
hooks = {
  # ... existing hooks ...
  MyEvent = [
    {
      type = "command";
      command = "~/.claude/hooks/<name>.sh";
    }
  ];
};
```

## Verification

```bash
nixos-rebuild build --flake .#nesco
```

After deploying:
```bash
ls -la ~/.claude/hooks/    # verify script is deployed
cat ~/.claude/settings.json | jq '.hooks'    # verify hook is registered
```

## Gotchas

- Hook scripts must be executable — use `executable = true` in `home.file`
- The notification hook system (`custom.claude.notifications`) is separate from direct hook entries — don't mix them
- Notification hooks are currently disabled in `home/users/aidanb/default.nix` (`custom.claude.notifications.enable = false`)
- Hook scripts are deployed as nix store symlinks — changes require a rebuild
- The `hooks` field in `claudeSettings` is conditionally generated — if notification hooks are enabled, they're merged in. Adding hooks directly requires understanding this merge logic.

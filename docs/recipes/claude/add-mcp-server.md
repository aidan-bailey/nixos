# Add an MCP Server

## When to use

When adding a new MCP (Model Context Protocol) server that Claude Code can use for tool access.

## Files to modify

1. **Modify** `.mcp.json` — add the server config (repo-level)
2. **Optionally modify** `home/modules/claude.nix` — if the server needs a package installed

## Steps

### 1. Add server to .mcp.json

`.mcp.json` in the repo root configures MCP servers:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "my-server-command",
      "args": ["--flag", "value"]
    }
  }
}
```

### 2. Install the server package (if needed)

In `home/modules/claude.nix`, add to `home.packages`:

```nix
home.packages = [
  # ... existing packages ...
  inputs.my-server.packages.${system}.default
  # or
  pkgs.my-server-package
];
```

### 3. For npx-based servers

Many MCP servers run via npx:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@scope/mcp-server-name"]
    }
  }
}
```

## Verification

```bash
nixos-rebuild build --flake .#nesco    # if package was added
```

Test the MCP server manually:
```bash
my-server-command --help
```

## Gotchas

- `.mcp.json` is a repo-level file, not Nix-generated — it can be edited directly
- The current `mcp-nixos` server is installed as a package with `doCheck = false` (tests disabled) — some MCP packages may need similar treatment
- MCP servers need their runtime dependencies on PATH — check that all required tools are in `home.packages`
- For servers that need API keys, consider using sops-nix secrets (see [Add a user secret](../secrets/add-user-secret.md))

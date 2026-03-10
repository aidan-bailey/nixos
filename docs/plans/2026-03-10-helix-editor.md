# Helix Editor Installation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the helix editor with LSP servers, formatters, and DAP debuggers as a home-manager module for desktop/laptop hosts.

**Architecture:** A self-contained `home/modules/helix.nix` using `programs.helix` with `extraPackages` for scoped LSP/formatter/DAP dependencies, `languages` for per-language configuration, and `settings` for editor preferences. Imported via `home/profiles/desktop.nix` so it only activates on nesco and fresco (not medesco server).

**Tech Stack:** NixOS home-manager `programs.helix` module, nixpkgs `helix` package, various LSP/formatter/DAP packages from nixpkgs.

---

### Task 1: Create the helix home-manager module

**Files:**
- Create: `home/modules/helix.nix`

**Step 1: Create `home/modules/helix.nix`**

This is a NixOS config, not a testable application, so we use build verification instead of TDD.

```nix
{ config, pkgs, ... }:

let
  # LSP servers
  lspPackages = with pkgs; [
    nixd
    pyright
    ruff
    rust-analyzer
    nodePackages.bash-language-server
    marksman
    yaml-language-server
    vscode-langservers-extracted # provides vscode-json-language-server
    nodePackages.typescript-language-server
    typescript # required by typescript-language-server
  ];

  # Formatters
  formatterPackages = with pkgs; [
    nixfmt
    shfmt
    nodePackages.prettier
  ];

  # DAP adapters
  dapPackages = with pkgs; [
    lldb # provides lldb-dap
  ];
in
{
  programs.helix = {
    enable = true;

    extraPackages = lspPackages ++ formatterPackages ++ dapPackages;

    settings = {
      theme = "gruvbox";
      editor = {
        mouse = true;
        auto-format = true;
        line-number = "relative";
        cursorline = true;
        idle-timeout = 50;
        completion-trigger-len = 1;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides = {
          render = true;
          character = "│";
        };
        statusline = {
          left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
          right = [ "diagnostics" "selections" "register" "position" "file-encoding" ];
        };
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };

      keys.normal = {
        space.w = ":write";
        space.q = ":quit";
      };
    };

    languages = {
      language-server = {
        nixd.command = "nixd";
        rust-analyzer = {
          command = "rust-analyzer";
          config.check.command = "clippy";
        };
        pyright = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
        };
        ruff = {
          command = "ruff";
          args = [ "server" ];
        };
        bash-language-server = {
          command = "bash-language-server";
          args = [ "start" ];
        };
        marksman.command = "marksman";
        yaml-language-server = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
        };
        vscode-json-language-server = {
          command = "vscode-json-language-server";
          args = [ "--stdio" ];
        };
        typescript-language-server = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
        };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "nixfmt";
          language-servers = [ "nixd" ];
        }
        {
          name = "rust";
          auto-format = true;
          language-servers = [ "rust-analyzer" ];
          debugger = {
            name = "lldb-dap";
            transport = "stdio";
            command = "lldb-dap";
            templates = [
              {
                name = "binary";
                request = "launch";
                completion = [ { name = "binary"; completion = "filename"; } ];
                args = { program = "{0}"; };
              }
            ];
          };
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [
            "pyright"
            { name = "ruff"; only-features = [ "format" "diagnostics" ]; }
          ];
          formatter = {
            command = "ruff";
            args = [ "format" "-" ];
          };
        }
        {
          name = "bash";
          auto-format = true;
          formatter.command = "shfmt";
          language-servers = [ "bash-language-server" ];
        }
        {
          name = "markdown";
          auto-format = false;
          language-servers = [ "marksman" ];
        }
        {
          name = "yaml";
          auto-format = true;
          language-servers = [ "yaml-language-server" ];
        }
        {
          name = "json";
          auto-format = true;
          language-servers = [ "vscode-json-language-server" ];
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [ "--parser" "typescript" ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [ "--parser" "babel" ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "tsx";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [ "--parser" "typescript" ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "jsx";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [ "--parser" "babel" ];
          };
          language-servers = [ "typescript-language-server" ];
        }
      ];
    };
  };
}
```

**Step 2: Commit**

```bash
git add home/modules/helix.nix
git commit -m "feat(helix): add helix editor home-manager module

Configures helix with LSP servers, formatters, and DAP debuggers
for Nix, Rust, Python, Bash, Markdown, YAML, JSON, and TypeScript.
Uses extraPackages for scoped dependency management."
```

---

### Task 2: Wire helix into the desktop profile

**Files:**
- Modify: `home/profiles/desktop.nix:3-8`

**Step 1: Add helix import to desktop profile**

Add `../modules/helix.nix` to the imports list in `home/profiles/desktop.nix`:

```nix
{ ... }:
{
  imports = [
    ../modules/wayland.nix
    ../modules/gaming.nix
    ../modules/apps.nix
    ../modules/research.nix
    ../modules/helix.nix
  ];
}
```

**Step 2: Commit**

```bash
git add home/profiles/desktop.nix
git commit -m "feat(helix): add helix to desktop profile imports"
```

---

### Task 3: Build verification

**Step 1: Format nix files**

```bash
nixfmt home/modules/helix.nix home/profiles/desktop.nix
```

**Step 2: Build nesco configuration (dry build, no activation)**

```bash
nixos-rebuild build --flake .#nesco 2>&1
```

Expected: Build succeeds without errors. If it fails, read the error output and fix the nix expression.

**Step 3: Build fresco configuration (dry build, no activation)**

```bash
nixos-rebuild build --flake .#fresco 2>&1
```

Expected: Build succeeds without errors.

**Step 4: Build medesco configuration (dry build, no activation)**

```bash
nixos-rebuild build --flake .#medesco 2>&1
```

Expected: Build succeeds without errors. Helix should NOT be included in this build since medesco uses serverModules only (no desktop profile).

**Step 5: Commit any formatting changes**

```bash
git add -A
git commit -m "style: format helix module with nixfmt"
```

Only commit if nixfmt made changes. If no changes, skip this step.

---

### Task 4: Verify helix is excluded from server builds

**Step 1: Check that medesco build does not include helix**

```bash
nix eval .#nixosConfigurations.medesco.config.home-manager.users.aidanb.programs.helix.enable 2>&1
```

Expected: `false` or an error indicating the option doesn't exist (both confirm helix is not enabled on the server).

**Step 2: Check that nesco build includes helix**

```bash
nix eval .#nixosConfigurations.nesco.config.home-manager.users.aidanb.programs.helix.enable 2>&1
```

Expected: `true`

**Step 3: Final commit with all changes**

If any fixes were needed during verification, commit them:

```bash
git add -A
git commit -m "fix(helix): address build verification issues"
```

Only commit if there are staged changes. If everything passed cleanly, skip this step.

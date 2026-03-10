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
          left = [
            "mode"
            "spinner"
            "file-name"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-encoding"
          ];
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
                completion = [
                  {
                    name = "binary";
                    completion = "filename";
                  }
                ];
                args = {
                  program = "{0}";
                };
              }
            ];
          };
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [
            "pyright"
            {
              name = "ruff";
              only-features = [
                "format"
                "diagnostics"
              ];
            }
          ];
          formatter = {
            command = "ruff";
            args = [
              "format"
              "-"
            ];
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
            args = [
              "--parser"
              "typescript"
            ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "babel"
            ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "tsx";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
          language-servers = [ "typescript-language-server" ];
        }
        {
          name = "jsx";
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "babel"
            ];
          };
          language-servers = [ "typescript-language-server" ];
        }
      ];
    };
  };
}

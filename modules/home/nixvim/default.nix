{ lib, pkgs, config, ... }:

{
  options = {
    nixvim = {
      enable = lib.mkOption {
        description = "Enable NixVim.";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.nixvim.enable {

    # NVIM setup
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;

      opts = {
        number = true;
        shiftwidth = 2;
        completeopt = [ "menu" "menuone" "noselect" ];
        termguicolors = true;
      };

      colorschemes.catppuccin.enable = true;

      extraPackages = with pkgs; [ pylint ];

      keymaps = let
        normal = lib.mapAttrsToList (key: action: {
          mode = "n";
          inherit action key;
        }) {
          # navigate between windows
          "<leader>h" = "<C-w>h";
          "<leader>l" = "<C-w>l";
          "-" = "<CMD>Oil<CR>"; # Open Oil Brower
          # open markdown preview
          "<leader>m" = ":MarkdownPreview<cr>";
        };
        visual = lib.mapAttrsToList (key: action: {
          mode = "v";
          inherit action key;
        }) { };
      in config.lib.nixvim.keymaps.mkKeymaps { options.silent = true; }
      (normal ++ visual);

      plugins = {
        cmp = {
          enable = true;
          settings = {
            snippet.expand =
              "function(args) require('luasnip').lsp_expand(args.body) end";
            mapping = {
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.close()";
              "<Tab>" =
                "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" =
                "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
            };
            sources = [
              { name = "path"; }
              { name = "nvim_lsp"; }
              { name = "luasnip"; }
              {
                name = "buffer";
                option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
              }
              { name = "neorg"; }
            ];
          };
        };

        comment = {
          enable = true;
          settings = {
            opleader.line = "<C-b>";
            toggler.line = "<C-b>";
          };
        };

        todo-comments = {
          enable = true;
          settings = {
            keywords = {
              TODO = {
                color = "warning";
                icon = " ";
              };
            };
            highlight = { pattern = ".*<(KEYWORDS)\\s*"; };
          };
        };

        copilot-lua = {
          enable = true;
          autoLoad = true;
        };

        copilot-chat = { enable = true; };

        emmet = { enable = true; };

        nvim-autopairs = { enable = true; };

        ts-autotag = { enable = true; };

        none-ls = {
          enable = true;
          settings = {
            cmd = [ "bash -c nvim" ];
            debug = true;
          };
          sources = {
            code_actions = {
              statix.enable = true;
              gitsigns.enable = true;
            };
            diagnostics = {
              statix.enable = true;
              deadnix.enable = true;
              pylint.enable = true;
              checkstyle.enable = true;
            };
            formatting = {
              alejandra.enable = true;
              stylua.enable = true;
              shfmt.enable = true;
              nixpkgs_fmt.enable = true;
              prettier = {
                enable = true;
                disableTsServerFormatter = true;
                settings = {
                  extra_filetypes = [ "vue" "json" ];
                  insert_final_newline = true;
                };
              };
              black = {
                enable = true;
                settings = ''
                  {
                    extra_args = { "--fast" },
                  }
                '';
              };
              xmllint = {
                enable = true;
                settings = { extra_filetypes = [ "svg" ]; };
              };
            };
            completion = {
              luasnip.enable = true;
              spell.enable = true;
            };
          };
        };

        lint = {
          enable = true;
          lintersByFt = {
            text = [ "vale" ];
            eslint = [ "eslint" ];
            json = [ "jsonlint" ];
            markdown = [ "vale" ];
            rst = [ "vale" ];
            ruby = [ "ruby" ];
            janet = [ "janet" ];
            inko = [ "inko" ];
            clojure = [ "clj-kondo" ];
            dockerfile = [ "hadolint" ];
            terraform = [ "tflint" ];
            python = [ "pylint" ];
          };
        };

        gitsigns = {
          enable = true;
          autoLoad = true;
          settings = { current_line_blame = true; };
        };

        gitmessenger = {
          enable = true;
          autoLoad = true;
        };

        diffview = { enable = true; };

        git-conflict = { enable = true; };

        lsp = {
          enable = true;
          servers = {
            ts_ls = {
              enable = true; # TS
              filetypes = [ "typescript" "typescriptreact" "typescript.tsx" ];
            };
            cssls.enable = true; # CSS
            tailwindcss.enable = true; # TailwindCSS
            html.enable = true; # HTML
            emmet_ls = {
              enable = true;
              filetypes = [
                "html"
                "css"
                "scss"
                "javascript"
                "javascriptreact"
                "typescript"
                "typescriptreact"
                "svelte"
                "vue"
              ];
            };
            svelte.enable = false; # Svelte
            volar = {
              enable = true; # Vue
              # volar formatter indent is broken, so we disable it in favor of prettier
              onAttach.function = ''
                     on_attach = function(client)
                client.server_capabilities.document_formatting = false
                client.server_capabilities.document_range_formatting = false
                     end
              '';
              onAttach.override = true;
            };
            angularls.enable = true; # Angular
            mdx_analyzer = {
              enable = true;
              package = null;
            };
            pyright.enable = true; # Python
            marksman.enable = true; # Markdown
            nil_ls.enable = true; # Nix
            dockerls.enable = true; # Docker
            bashls.enable = true; # Bash
            yamlls.enable = true; # YAML
            lua_ls = {
              enable = true;
              settings.telemetry.enable = false;
            };
          };
        };

        lsp-format = { enable = true; };

        lsp-status = { enable = true; };

        lspkind = {
          enable = true;
          cmp = {
            enable = true;
            menu = {
              nvim_lsp = "[LSP]";
              nvim_lua = "[api]";
              path = "[path]";
              luasnip = "[snip]";
              buffer = "[buffer]";
              neorg = "[neorg]";
            };
          };
        };

        lualine = { enable = true; };

        trouble = {
          enable = true;
          settings = { multiline = true; };
        };

        luasnip.enable = true;

        web-devicons = { enable = true; };

        startify = {
          enable = true;
          settings = {
            custom_header = [
              ""
              "     ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "     ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "     ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "     ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "     ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];

            change_to_dir = false;
            use_unicode = true;
            lists = [{ type = "dir"; }];
            files_number = 30;
            autoExpandWidth = true;
            skiplist = [ "flake.lock" ];
          };
        };

        barbar = {
          enable = true;
          keymaps = {
            next.key = "<TAB>";
            previous.key = "<S-TAB>";
            close.key = "<C-w>";
          };
        };

        neo-tree = {
          enable = true;
          enableGitStatus = true;
          enableModifiedMarkers = true;
          enableRefreshOnWrite = true;
          closeIfLastWindow = true;
          buffers = {
            bindToCwd = false;
            followCurrentFile = { enabled = true; };
          };
          filesystem = {
            filteredItems = {
              hideDotfiles = false;
              alwaysShow = [ "node_modules" "dist" "'[A-Z]*'" ];
              visible = true;
            };
          };
        };

        undotree = {
          enable = true;
          settings = {
            autoOpenDiff = true;
            focusOnToggle = true;
          };
        };

        notify = { enable = true; };

        nui = { enable = true; };

        noice = { enable = true; };

        transparent = {
          enable = true;
          settings = {
            groups = [
              "Normal"
              "NormalNC"
              "Comment"
              "Constant"
              "Special"
              "Identifier"
              "Statement"
              "PreProc"
              "Type"
              "Underlined"
              "Todo"
              "String"
              "Function"
              "Conditional"
              "Repeat"
              "Operator"
              "Structure"
              # "LineNr"
              "NonText"
              # "SignColumn"
              "CursorLine"
              "CursorLineNr"
              "StatusLine"
              "StatusLineNC"
              "EndOfBuffer"
            ];
            exclude_groups = [ "LineNr" "SignColumn" ];
          };
        };

        markdown-preview = {
          enable = true;
          settings = {
            auto_close = 0;
            theme = "dark";
          };
        };

        image = { enable = true; };

        treesitter = {
          enable = true;
          nixvimInjections = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
          folding = false;
        };

        colorizer = {
          enable = true;
          settings = {
            user_default_options = {
              AARRGGBB = true;
              RGB = true;
              RRGGBB = true;
              RRGGBBAA = true;
              css = true;
              css_fn = true;
              hsl_fn = true;
              mode = "background";
              names = true;
              rgb_fn = true;
              tailwind = true;
            };
          };
        };

        telescope = {
          enable = false;
          extensions = {
            media-files = {
              enable = true;
              settings = {
                filetypes = [ "png" "jpg" "jpeg" "webp" "gif" ];
                find_cmd = "rg";
              };
            };
          };
          keymaps = {
            # Find files using Telescope command-line sugar.
            "<leader>ff" = "find_files";
            "<leader>fg" = "live_grep";
            "<leader>b" = "buffers";
            "<leader>fh" = "help_tags";
            "<leader>fd" = "diagnostics";
            "<leader>mf" = "media_files";

            # FZF like bindings
            "<C-p>" = "git_files";
            "<leader>p" = "oldfiles";
            "<C-f>" = "live_grep";
          };
          settings.defaults = {
            file_ignore_patterns = [
              "^.git/"
              "^.mypy_cache/"
              "^__pycache__/"
              "^output/"
              "^data/"
              "%.ipynb"
            ];
            set_env.COLORTERM = "truecolor";
          };
        };

        oil = { enable = true; };
        oil-git-status { enable = true; };
    };
  };
}

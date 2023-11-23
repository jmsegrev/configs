local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "yaml",
    "json",
    "python",
    "bash",
    "dockerfile",
    "go",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "tailwindcss-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = false,
      },
    },

    root_folder_label = function(path)
      -- show root folder label as grandparent/parent directory
      -- return ".../" .. vim.fn.fnamemodify(path, ":h:t") .. "/" .. vim.fn.fnamemodify(path, ":t")
      -- show root folder label as parent directory
      return ".../" .. vim.fn.fnamemodify(path, ":t")
    end
  },
  filters = {
    git_ignored = false,
  },
  view = {
    side = "right",
    width = 35,
  },
  respect_buf_cwd = true,
  sync_root_with_cwd = false,
  update_focused_file = {
    enable = true,
    update_root = true,
  },
  on_attach = function(bufnr)
    local api = require "nvim-tree.api"

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- custom mappings
    local useful_keys = {
      ["l"] = { api.node.open.edit, opts "Open" },
      ["o"] = { api.node.open.edit, opts "Open" },
      ["v"] = { api.node.open.vertical, opts "Open: Vertical Split" },
      ["h"] = { api.node.navigate.parent_close, opts "Close Directory" },
      ["<CR>"] = { api.tree.change_root_to_node, opts "CD" },
      -- ["gtg"] = { telescope_live_grep, opts "Telescope Live Grep" },
      -- ["gtf"] = { telescope_find_files, opts "Telescope Find File" },
    }

    for key, value in pairs(useful_keys) do
      vim.keymap.set("n", key, value[1], value[2])
    end
  end,
}

M.yanky = {
  highlight = {
    on_put = false,
    on_yank = false,
  },
}

M.copilot = {
  -- Possible configurable fields can be found on:
  -- https://github.com/zbirenbaum/copilot.lua#setup-and-configuration
  suggestion = {
    auto_trigger = true,
  },
}

return M

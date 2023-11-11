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
  },
  view = {
    side = "right",
    width = 35,
  },
  respect_buf_cwd = true,
  update_cwd = true,
  update_focused_file = {
    enable = true,
    debounce_delay = 15,
    update_root = true,
    ignore_list = {},
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

return M

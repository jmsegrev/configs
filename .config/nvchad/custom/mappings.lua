---@type MappingsTable
local M = {}

M.disabled = {
  n = {
    ["<C-n>"] = "",
    ["<C-p>"] = "",
  },
}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    ["<C-p>"] = { "<Plug>(YankyCycleForward)", "Yank Put Forward" },
    ["<C-n>"] = { "<Plug>(YankyCycleBackward)", "Yank Put Backward" },
    ["p"] = { "<Plug>(YankyPutAfter)", "Yanky Put After" },
    ["P"] = { "<Plug>(YankyPutBefore)", "Yanky Put Before" },
    ["gp"] = { "<Plug>(YankyGPutAfter)", "Yanky GPut After" },
    ["gP"] = { "<Plug>(YankyGPutBefore)", "Yanky GPut Before" },
  },
  v = {
    [">"] = { ">gv", "indent" },
  },
}

M.nvimtree = {
  plugin = true,

  n = {
    ["<leader>e"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<C-l>"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },

    ["<C-h>"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },

    -- close buffer + hide terminal buffer
    -- ["<leader>c"] = {
    --   function()
    --     require("nvchad.tabufline").close_buffer()
    --   end,
    --   "Close buffer",
    -- },
    --
  },
}

M.copilot = {
  -- github copilot
  -- i = {
  --   ["<C-l>"] = {
  --     function()
  --       vim.fn.feedkeys(vim.fn['copilot#Accept'](), '')
  --     end,
  --     "Copilot Accept",
  --     {replace_keycodes = true, nowait=true, silent=true, expr=true, noremap=true}
  --   }
  -- }
  -- copilot.lua
  i = {
    ["<C-l>"] = {
      function()
        require("copilot.suggestion").accept()
      end,
      "Copilot Accept",
      {replace_keycodes = true, nowait=true, silent=true, expr=true, noremap=true}
    }
  }
}

return M

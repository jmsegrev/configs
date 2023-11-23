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
  t = {
    -- allows for switching window while in terminal in the same way as normal mode
    ["<C-w>"] = {
      function()
        local buf_nb = vim.api.nvim_get_current_buf()
        vim.api.nvim_command "stopinsert"
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-w>", true, true, true), "n", false)

        -- go back to insert mode if we end up in the same terminal
        vim.schedule(function()
          local new_buf_nb = vim.api.nvim_get_current_buf()
          if new_buf_nb == buf_nb then
            vim.api.nvim_command "startinsert"
          end
        end)
      end,
    },
  },
}

M.nvimtree = {
  plugin = true,

  n = {
    -- open nvimtree in dir of the current open file buf
    ["<leader>e"] = { "<cmd>cd %:p:h<CR><cmd>NvimTreeToggle<CR>", "Toggle nvimtree in open buf dir" },
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
      { replace_keycodes = true, nowait = true, silent = true, expr = true, noremap = true },
    },
  },
}

return M

return {
  "folke/which-key.nvim",
  opts = {
    win = {
      -- Customize which-key floating window position here
      width = { min = 30, max = 60 }, -- Min 30 cols, max 60 cols
      height = { min = 4, max = 0.75 }, -- Min 4 lines, max 75% of screen
      col = -1, -- Position: -1 = bottom-right, 0 = left, 0.5 = center, 1 = right
      row = -3, -- Position: -1 = bottom, 0 = top, 0.5 = center, 1 = bottom
      border = "rounded",
      padding = { 0, 1 }, -- Top/bottom, left/right padding
      title = true,
      title_pos = "left", -- "left", "center", or "right"
    },
  },
  keys = {
    {
      "<leader>",
      function()
        -- Close explorer if open
        local pickers = require("snacks.picker").get({ source = "explorer" })
        for _, picker in ipairs(pickers) do
          picker:close()
        end
        -- Trigger which-key with leader context
        require("which-key").show(" ")
      end,
      mode = { "n", "v" },
    },
  },
}

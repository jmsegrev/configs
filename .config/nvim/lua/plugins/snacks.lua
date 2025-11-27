return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>E",
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= "" then
          -- If buffer has a file, open explorer in that file's directory
          local dir = vim.fn.fnamemodify(bufname, ":h")
          Snacks.explorer({ cwd = dir })
        else
          -- If no file in buffer, open in cwd
          Snacks.explorer()
        end
      end,
      desc = "Explorer (buffer dir)",
    },
  },
  opts = {
    picker = {
      sources = {
        explorer = {
          layout = {
            hidden = { "input" }, -- Hide input field by default
            layout = {
              backdrop = false,
              row = -2.5, -- Bottom of screen (like which-key)
              col = -1, -- Right side (like which-key)
              width = 34,
              min_width = 34,
              max_width = 34,
              height = 0.8,
              border = "rounded",
              box = "vertical",
              { win = "list", border = "none" },
            },
          },
        },
      },
    },
  },
}

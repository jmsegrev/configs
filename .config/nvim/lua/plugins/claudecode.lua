return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    command = vim.fn.expand("$HOME") .. "/.claude/local/node_modules/.bin/claude",
  },
}

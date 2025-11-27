return {
  -- BAML LSP and treesitter setup
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- Register BAML language for treesitter
      vim.treesitter.language.register("baml", "baml")

      -- BAML LSP configuration
      vim.lsp.config.baml_lsp = {
        cmd = { "/home/jmsegrev/.nvm/versions/node/v22.21.1/bin/baml-cli", "lsp" },
        root_markers = { "baml_src", ".git" },
        filetypes = { "baml" },
      }
      vim.lsp.enable("baml_lsp")

      -- Set commentstring for BAML files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "baml",
        callback = function()
          vim.bo.commentstring = "// %s"
        end,
      })
    end,
  },
}

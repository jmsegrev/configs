return {
  {
    "jmsegrev/lsp_lines.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_lines").setup()

      -- Disable virtual_text since lsp_lines will show diagnostics
      vim.diagnostic.config({
        virtual_text = false,
      })
    end,
    keys = {
      {
        "<leader>x", -- fast will show the line, slow will show which-keys
        function()
          require("lsp_lines").toggle()
        end,
        desc = "Toggle lsp_lines",
      },
    },
  },

  -- LSP configuration adjustments
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- Fix for BAML LSP duplicate diagnostics with lsp_lines
      -- BAML LSP creates diagnostics in two namespaces causing duplicates
      local original_diagnostic_set = vim.diagnostic.set
      vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
        local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
        if ft == "baml" then
          local ns_info = vim.diagnostic.get_namespace(namespace)
          local ns_name = ns_info and ns_info.name or ""
          -- Skip the duplicate ".BAML" namespace
          if ns_name:match("%.BAML$") then
            return
          end
        end
        return original_diagnostic_set(namespace, bufnr, diagnostics, opts)
      end
    end,
  },
}

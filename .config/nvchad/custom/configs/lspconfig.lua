local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "clangd", "tailwindcss" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.denols.setup {
  on_attach = on_attach,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.tsserver.setup {
  on_attach = function(client, bufnr)
    local get_root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc")
    local buf_dir = vim.api.nvim_buf_get_name(bufnr):match "(.*[/\\])"

    -- disable tsserver for deno projects
    local is_deno = vim.fn.filereadable(get_root_dir(buf_dir) .. "/deno.json") == 1
    if is_deno then
      client.stop()
      return
    end
    on_attach(client, bufnr)
  end,
}

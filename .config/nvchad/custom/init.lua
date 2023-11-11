local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

-- changes buf filetype
-- autocmd("BufRead", {
--   pattern = "*.ts,*.js,*.tsx,*.jsx",
--   callback = function(buf)
--     local lspconfig = require "lspconfig"
--     local get_root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc")
--     local buf_dir = buf.match:match "(.*[/\\])"
--     local is_deno = vim.fn.filereadable(get_root_dir(buf_dir) .. "/deno.json") == 1
--     local ext = vim.fn.expand("%:e", true, buf.buf)[1]
--
--     if is_deno then
--         vim.api.nvim_buf_set_option(buf.buf, "filetype", "deno." .. ext)
--     end
--   end,
-- })

-- disable tsserver for deno projects
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(t)
--     local client = vim.lsp.get_client_by_id(t.data.client_id)
--     if t.buf ~= vim.api.nvim_get_current_buf() or client.name ~= "tsserver" then
--       return
--     end
--     local get_root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc")
--     local is_deno = vim.fn.filereadable(get_root_dir(t.file) .. "/deno.json") == 1
--     if is_deno then
--       vim.defer_fn(function()
--         -- TODO this seems to be the same as client.stop
--         vim.lsp.buf_detach_client(t.buf, t.data.client_id)
--       end, 100)
--     end
--   end,
-- })



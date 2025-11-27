-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- tmux-window-name integration
vim.api.nvim_create_autocmd({ "BufEnter", "VimEnter" }, {
  callback = function()
    if vim.env.TMUX then
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname ~= "" then
        -- Get full path and replace home directory with ~
        local filename = vim.fn.fnamemodify(bufname, ":p")
        local home = vim.env.HOME
        if home and filename:sub(1, #home) == home then
          filename = "~" .. filename:sub(#home + 1)
        end
        -- Rename tmux window to the path with vim: prefix
        vim.fn.system("tmux rename-window 'vim:" .. filename:gsub("'", "'\\''") .. "'")
      end
    end
  end,
})

-- Reset tmux window name when leaving Neovim
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    if vim.env.TMUX then
      vim.fn.system("tmux rename-window 'bash'")
    end
  end,
})

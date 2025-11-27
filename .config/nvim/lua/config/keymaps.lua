-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = LazyVim.safe_keymap_set

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<C-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")

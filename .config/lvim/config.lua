--[[
lvim is the global options object

Linters should be filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "myonedarker"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping

lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
-- unmap a default keymapping
-- lvim.keys.normal_mode["<C-Up>"] = false
-- edit a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>"

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
-- local _, actions = pcall(require, "telescope.actions")
-- lvim.builtin.telescope.defaults.mappings = {
--   -- for input mode
--   i = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--     ["<C-n>"] = actions.cycle_history_next,
--     ["<C-p>"] = actions.cycle_history_prev,
--   },
--   -- for normal mode
--   n = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--   },
-- }

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble lsp_document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble lsp_workspace_diagnostics<cr>", "Diagnostics" },
-- }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.notify.active = false
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "right"
lvim.builtin.nvimtree.setup.view.width = 35
lvim.builtin.nvimtree.setup.view.auto_resize = true
lvim.builtin.dap.active = true
-- remove x from tabs
lvim.builtin.bufferline.options.buffer_close_icon = ""
-- remove nvimtree header in tabs
local bufferline_offset = lvim.builtin.bufferline.options.offsets[2]
if bufferline_offset.filetype == "NvimTree" then
	table.remove(lvim.builtin.bufferline.options.offsets, 2)
end

-- Add useful keymaps
local _, nvim_tree_config = pcall(require, "nvim-tree.config")
local tree_cb = nvim_tree_config.nvim_tree_callback
if #lvim.builtin.nvimtree.setup.view.mappings.list == 0 then
	lvim.builtin.nvimtree.setup.view.mappings.list = {
		{ key = { "l", "o" }, cb = tree_cb("edit") },
		{ key = "h", cb = tree_cb("close_node") },
		{ key = "v", cb = tree_cb("vsplit") },
		{ key = { "C", "<CR>" }, cb = tree_cb("cd") }, -- I've only added enter <CR> to cd dir, the rest from LunarVim defaults
		{ key = "gtf", cb = "<cmd>lua require'lvim.core.nvimtree'.start_telescope('find_files')<cr>" },
		{ key = "gtg", cb = "<cmd>lua require'lvim.core.nvimtree'.start_telescope('live_grep')<cr>" },
		{ key = "t", cb = "<cmd>lua Custom.nvim_tree_toggle_terminal_on_file_dir()<cr>" },
	}
end

lvim.builtin.nvimtree.show_icons.git = 0

-- lvim.builtin.nvimtree.update_cwd = false
-- lvim.builtin.nvimtree.respect_buf_cwd = 0
-- lvim.builtin.nvimtree.setup.update_cwd = false
-- lvim.builtin.nvimtree.setup.update_focused_file = { enable = false, update_cwd = false }

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
	"bash",
	"c",
	"javascript",
	"json",
	"lua",
	"python",
	"typescript",
	"css",
	"scss",
	"html",
	"rust",
	"java",
	"yaml",
	"graphql",
	"svelte",
	"go",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- generic LSP settings

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---@usage Select which servers should be configured manually. Requires `:LvimCacheRest` to take effect.
-- See the full default list `:lua print(vim.inspect(lvim.lsp.override))`
-- vim.list_extend(lvim.lsp.override, { "pyright" })

-- ---@usage setup a server -- see: https://www.lunarvim.org/languages/#overriding-the-default-configuration
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pylsp", opts)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
-- local formatters = require "lvim.lsp.null-ls.formatters"
-- formatters.setup {
--   { command = "black", filetypes = { "python" } },
--   { command = "isort", filetypes = { "python" } },
--   {
--     -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "prettier",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--print-with", "100" },
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "typescript", "typescriptreact" },
--   },
-- }

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }

-- Additional Plugins
-- lvim.plugins = {
--     {"folke/tokyonight.nvim"},
--     {
--       "folke/trouble.nvim",
--       cmd = "TroubleToggle",
--     },
-- }

-------------------------------------------------------------

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#svelte
-- yarn global add svelte-language-server
require("lvim.lsp.manager").setup("svelte")

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#angularls
-- yarn global add @angular/language-server
require("lvim.lsp.manager").setup("angularls")

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#eslint
-- yarn global add vscode-langservers-extracted
require("lvim.lsp.manager").setup("eslint")

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#tailwindcss
-- yarn global add tailwindcss-language-server
require("lvim.lsp.manager").setup("tailwindcss")

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#graphql
-- yarn global add graphql-language-service-cli
require("lvim.lsp.manager").setup("graphql", {
	filetypes = { "graphql", "gql" },
})

-- yarn global add emmet-ls
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#emmet_ls
require("lvim.lsp.manager").setup("emmet_ls")

-- requires rust to be installed
require("lvim.lsp.manager").setup("rust_analyzer")

local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{
		-- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
		command = "prettier",
		---@usage arguments to pass to the formatter
		-- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
		extra_args = { "--print-with", "80" },
		---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
		filetypes = {
			"graphql",
			"typescript",
			"javascript",
			"html",
			"css",
			"scss",
			"json",
			"md",
			"gql",
			"yaml",
			"yml",
			"svelte",
		},
	},
	{
		-- https://github.com/JohnnyMorganz/StyLua
		command = "stylua",
	},
	{
		-- https://github.com/avencera/rustywind
		command = "rustywind",
	},
	{
		command = "black",
		extra_args = { "--line-length", "79" },
		filetypes = { "python" },
	},
	{
		command = "isort",
		filetypes = { "python" },
	},
	{
		command = "rustfmt",
	},
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ command = "flake8", filetypes = { "python" } },
	-- {
	-- 	-- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
	-- 	command = "shellcheck",
	-- 	---@usage arguments to pass to the formatter
	-- 	-- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
	-- 	extra_args = { "--severity", "warning" },
	-- },
	-- {
	-- 	command = "codespell",
	-- 	---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
	-- 	filetypes = { "javascript", "python" },
	-- },
})

lvim.plugins = {
	{ "vim-scripts/YankRing.vim" },
	{ "mg979/vim-visual-multi" },
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup({ "*" })
		end,
	},
	{ "jmsegrev/myonedarker.nvim" },
}

vim.g.yankring_history_dir = "~/.config/lvim/"

-- do not allow the mouse to be used in neovim
vim.opt.mouse = ""

-- slow suggestion dialog display
vim.opt.timeoutlen = 200

-- lvim.keys.normal_mode["<C-h>"] = ":BufferPrevious<CR>"
-- lvim.keys.normal_mode["<C-l>"] = ":BufferNext<CR>"
lvim.keys.normal_mode["<C-h>"] = ":bprev<CR>"
lvim.keys.normal_mode["<C-l>"] = ":bnext<CR>"

-- shows diagnostic in a floating window
lvim.builtin.which_key.mappings["d"] = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Show Diagnostic" }

-- lvim.keys.normal_mode["<s-q>"] = "<cmd>BufferKill<CR>>"

-- Function to open neovim terminal emulator in the nvim-tree file under cursor directory path
-- key mapping set around line 73
Custom = {}
function Custom.nvim_tree_toggle_terminal_on_file_dir()
	local node = require("nvim-tree.lib").get_node_at_cursor()
	local path = node.absolute_path

	if not path or path == "" then
		return
	end

	if node.extension then
		path = path:match("(.*/)")
	end

	vim.cmd("ToggleTerm dir=" .. path)
end

-- commented around line 91 the following, to remove header from nvimtree
-- ~/.local/share/lunarvim/lvim/lua/lvim/core/bufferline.lua
-- options.offset
-- {
--   filetype = "NvimTree",
--   text = "Explorer",
--   highlight = "PanelHeading",
--   padding = 1,
-- },

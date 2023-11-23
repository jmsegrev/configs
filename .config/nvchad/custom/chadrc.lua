---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
  theme = "ayu_dark",
  theme_toggle = { "ayu_dark", "one_light" },

  hl_override = highlights.override,
  hl_add = highlights.add,
  tabufline = {
    -- changes order for tabufline to have nvimtree on the right
    overriden_modules = function(modules)
      table.insert(modules, modules[1])
      table.remove(modules, 1)
      -- table.remove(modules, 3)
    end,
  },
  statusline = {
    -- separator_style = "default",
    -- overrides file info modeule to show full path of open file
    overriden_modules = function(modules)
      modules[2] = (function()
        local icon = " 󰈚 "
        local path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(vim.g.statusline_winid))
        local name = (path == "" and "Empty ") or path

        -- for nvimtree buffer, show path
        local keyword = "NvimTree"
        if string.find(name, keyword) then
          local tree = require "nvim-tree.lib"
          local node = tree.get_node_at_cursor()
          if node and node.absolute_path then
            -- show path of file under cursor
            name = node.absolute_path
          else
            -- show path for dir (no file under cursor)
            -- removes /NvimTree_# 
            name = name:gsub("/" .. keyword .. "_%d+", "")
          end
          -- TODO color Explorer keyword
          name = "Explorer " .. name
        end

        if name ~= "Empty " then
          local home = os.getenv "HOME"
          -- replaces absolute home path with ~
          name = string.gsub(name, "%" .. home, "~")

          local devicons_present, devicons = pcall(require, "nvim-web-devicons")

          if devicons_present then
            local ft_icon = devicons.get_icon(name)
            icon = (ft_icon ~= nil and " " .. ft_icon) or icon
          end

          name = " " .. name .. " "
        end

        return "%#St_file_info#" .. icon .. name .. "%#St_file_sep#" .. ""
      end)()
      -- removes dir module
      modules[9] = ""
      -- overrides cursor position module to remove color and sign
      modules[10] = (function()
        local left_sep = "·  "

        local current_line = vim.fn.line(".", vim.g.statusline_winid)
        local total_line = vim.fn.line("$", vim.g.statusline_winid)
        local text = math.modf((current_line / total_line) * 100) .. tostring "%%"
        text = string.format("%4s", text)

        text = (current_line == 1 and "Top") or text
        text = (current_line == total_line and "Bot") or text

        return left_sep .. " " .. text .. " "
      end)()
    end,
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = opts.options.theme or "auto"

      -- Remove the time from lualine_z
      opts.sections.lualine_z = {}

      -- Remove filename/path from lualine_c but keep diagnostics and function name
      opts.sections.lualine_c = {
        {
          "diagnostics",
          symbols = {
            error = require("lazyvim.config").icons.diagnostics.Error,
            warn = require("lazyvim.config").icons.diagnostics.Warn,
            info = require("lazyvim.config").icons.diagnostics.Info,
            hint = require("lazyvim.config").icons.diagnostics.Hint,
          },
        },
      }

      -- Add trouble symbols to show current function name
      if vim.g.trouble_lualine and require("lazyvim.util").has("trouble.nvim") then
        local trouble = require("trouble")
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end

      -- Make lualine transparent by overriding section backgrounds
      local function setup_transparent_lualine()
        local colors =
          require("lualine.themes." .. (opts.options.theme == "auto" and "catppuccin" or opts.options.theme))

        -- Set all section backgrounds to transparent
        for _, mode in pairs(colors) do
          if type(mode) == "table" then
            for section, hl in pairs(mode) do
              if type(hl) == "table" then
                hl.bg = "NONE"
              end
            end
          end
        end

        return colors
      end

      -- Use transparent theme
      vim.defer_fn(function()
        opts.options.theme = setup_transparent_lualine()
      end, 0)

      return opts
    end,
  },
}

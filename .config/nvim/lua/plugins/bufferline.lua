return {
  {
    "akinsho/bufferline.nvim",
    opts = function()
      local bg_inactive = "#111215"
      local bg_active = "#000000"

      return {
        options = {
          separator_style = { "", "" },
          indicator = {
            style = "none",
          },
          show_buffer_close_icons = false,
          show_close_icon = false,
        },
        highlights = {
          fill = {
            bg = bg_inactive,
          },
          background = {
            bg = bg_inactive,
          },
          buffer_selected = {
            bg = bg_active,
          },
          -- LSP diagnostic states (inactive)
          error = {
            bg = bg_inactive,
          },
          warning = {
            bg = bg_inactive,
          },
          info = {
            bg = bg_inactive,
          },
          hint = {
            bg = bg_inactive,
          },
          -- LSP diagnostic states (selected/active)
          error_selected = {
            bg = bg_active,
          },
          warning_selected = {
            bg = bg_active,
          },
          info_selected = {
            bg = bg_active,
          },
          hint_selected = {
            bg = bg_active,
          },
          -- LSP diagnostic icons/numbers (inactive)
          error_diagnostic = {
            bg = bg_inactive,
          },
          warning_diagnostic = {
            bg = bg_inactive,
          },
          info_diagnostic = {
            bg = bg_inactive,
          },
          hint_diagnostic = {
            bg = bg_inactive,
          },
          -- LSP diagnostic icons/numbers (selected)
          error_diagnostic_selected = {
            bg = bg_active,
          },
          warning_diagnostic_selected = {
            bg = bg_active,
          },
          info_diagnostic_selected = {
            bg = bg_active,
          },
          hint_diagnostic_selected = {
            bg = bg_active,
          },
        },
      }
    end,
    config = function(_, opts)
      -- Monkey-patch bufferline to only color icons on selected buffers
      local highlights_module = require("bufferline.highlights")
      local original_set_icon_highlight = highlights_module.set_icon_highlight
      local constants = require("bufferline.constants")
      local visibility = constants.visibility

      highlights_module.set_icon_highlight = function(state, hls, base_hl)
        local PREFIX = "BufferLine"
        local state_props = ({
          [visibility.INACTIVE] = { "Inactive", hls.buffer_visible },
          [visibility.SELECTED] = { "Selected", hls.buffer_selected },
          [visibility.NONE] = { "", hls.background },
        })[state]
        local icon_hl, parent = PREFIX .. base_hl .. state_props[1], state_props[2]

        -- For inactive buffers, use the parent's foreground color
        if state ~= visibility.SELECTED then
          local parent_fg = parent.fg
          vim.api.nvim_set_hl(0, icon_hl, {
            fg = parent_fg,
            bg = parent.bg,
            italic = false,
            bold = false,
          })
          return icon_hl
        else
          -- For selected buffers, use the original function (colored icons)
          return original_set_icon_highlight(state, hls, base_hl)
        end
      end

      require("bufferline").setup(opts)
    end,
  },
}

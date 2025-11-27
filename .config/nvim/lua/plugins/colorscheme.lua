return {
  -- Configure catppuccin with transparent background
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      float = {
        transparent = true,
      },
      styles = {
        sidebars = "transparent",
      },
      integrations = {
        snacks = true,
      },
      color_overrides = {
        mocha = {},
      },
      custom_highlights = function(colors)
        return {
          StatusLine = { bg = "NONE" },
          StatusLineNC = { bg = "NONE" },
          Comment = { fg = colors.overlay1, style = { "italic" } },
        }
      end,
    },
  },

  -- Configure tokyonight with transparent background
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        hl.StatusLine = { bg = "NONE" }
        hl.StatusLineNC = { bg = "NONE" }
      end,
    },
  },

  -- Configure LazyVim to load catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  opts = {
    options = {
      mode = "tabs",
      separator_style = "slant",
      show_buffer_close_icons = false,
      show_close_icon = false,
      path = "none", -- Don't show any path, just filename
    },
  },
}

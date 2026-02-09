return {
  "mistricky/codesnap.nvim",
  tag = "v2.0.0-beta.16",
  lazy = true,
  keys = {
    { "<leader>cc", ":'<,'>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
  },
  config = function()
    require("codesnap").setup({
      snapshot_config = {
        theme = "candy",
        background = "#00000000",
        window = {
          margin = {
            x = 10,
            y = 80,
          },
        },
        watermark = {
          content = "",
        },
      },
    })
  end,
}

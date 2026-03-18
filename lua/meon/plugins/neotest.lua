return {
  "nvim-neotest/neotest",
  keys = { "<leader>tr", "<leader>tf", "<leader>ts", "<leader>to", "<leader>tO", "<leader>td", "<leader>tx" },
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "Issafalcon/neotest-dotnet",
  },
  config = function()
    require("neotest").setup({
      icons = {
        running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      },
      running = {
        concurrent = false,
      },
      adapters = {
        require("neotest-dotnet")({
          dap = {
            adapter_name = "netcoredbg",
          },
          discovery_root = "project",
          dotnet_additional_args = {
            "--no-build",
          },
        }),
      },
    })

    local map = vim.keymap.set

    map("n", "<leader>tr", "<Cmd>lua require('neotest').run.run()<CR>", { desc = "run nearest test" })
    map("n", "<leader>tf", "<Cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>", { desc = "run file tests" })
    map("n", "<leader>ts", "<Cmd>lua require('neotest').summary.toggle()<CR>", { desc = "toggle test summary" })
    map("n", "<leader>to", "<Cmd>lua require('neotest').output.open({ enter = true })<CR>", { desc = "open test output" })
    map("n", "<leader>tO", "<Cmd>lua require('neotest').output_panel.toggle()<CR>", { desc = "toggle output panel" })
    map("n", "<leader>td", "<Cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>", { desc = "debug nearest test" })
    map("n", "<leader>tx", "<Cmd>lua require('neotest').run.stop()<CR>", { desc = "stop running tests" })
  end,
}

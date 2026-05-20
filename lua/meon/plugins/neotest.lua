return {
  "nvim-neotest/neotest",
  keys = { "<leader>tr", "<leader>tf", "<leader>ts", "<leader>to", "<leader>tO", "<leader>td", "<leader>tx" },
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "Issafalcon/neotest-dotnet",
      -- Upstream is unpatched for Neovim 0.11+: framework-discovery uses
      -- iter_matches captures as single nodes, but 0.11+ returns them as lists,
      -- which breaks test discovery. Re-applied after every install/update.
      build = function(plugin)
        local file = plugin.dir .. "/lua/neotest-dotnet/framework-discovery.lua"
        local f = io.open(file, "r")
        if not f then
          return
        end
        local content = f:read("*a")
        f:close()
        content = content:gsub(
          "local test_attribute = vim%.fn%.has%(\"nvim%-0%.9%.0\"%) == 1\n        and vim%.treesitter%.get_node_text%(captures%[1%], source%)\n      or vim%.treesitter%.query%.get_node_text%(captures%[1%], source%)",
          "local capture = vim.fn.has(\"nvim-0.11\") == 1 and captures[1][1] or captures[1]\n    local test_attribute = vim.fn.has(\"nvim-0.9.0\") == 1\n        and vim.treesitter.get_node_text(capture, source)\n      or vim.treesitter.query.get_node_text(capture, source)"
        )
        local w = io.open(file, "w")
        if w then
          w:write(content)
          w:close()
        end
      end,
    },
  },
  config = function()
    require("neotest").setup({
      log_level = vim.log.levels.DEBUG,
      icons = {
        running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      },
      running = {
        concurrent = false,
      },
      discovery = {
        -- These contain scaffolding/copies with [Test] files but no .csproj,
        -- which make the dotnet adapter crash on a nil project root.
        filter_dir = function(name)
          return name ~= "templates" and name ~= "worktrees"
        end,
      },
      adapters = {
        require("neotest-dotnet")({
          dap = {
            adapter_name = "netcoredbg",
          },
          discovery_root = "project",
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

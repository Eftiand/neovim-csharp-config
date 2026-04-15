return {
  "rcarriga/nvim-dap-ui",
  dependencies = {
    "mfussenegger/nvim-dap",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dapui = require("dapui")
    local dap = require("dap")

    -- Auto close UI (no auto-open - use <leader>du to toggle)
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    -- Breakpoint symbols
    vim.fn.sign_define("DapBreakpoint", { text = "⚪" })
    vim.fn.sign_define("DapStopped", { text = "🔴" })
    vim.fn.sign_define("DapBreakpointRejected", { text = "⭕" })

    -- Minimal UI - scopes only at bottom
    dapui.setup({
      expand_lines = false,
      controls = { enabled = false },
      floating = { border = "rounded" },
      render = {
        max_type_length = 60,
        max_value_lines = 10,
      },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.6666 },
            { id = "watches", size = 0.3334 },
          },
          size = 15,
          position = "bottom",
        },
      },
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
    vim.keymap.set({ "n", "v" }, "<leader>dw", function() dapui.eval(nil, { enter = true }) end, { desc = "Watch" })
    vim.keymap.set({ "n", "v" }, "Q", dapui.eval, { desc = "Eval hover" })
  end,
}

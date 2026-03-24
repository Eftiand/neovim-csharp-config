return {
  "mfussenegger/nvim-dap",
  lazy = false,
  dependencies = {
    "Cliffback/netcoredbg-macOS-arm64.nvim",
  },
  config = function()
    local dap = require("dap")

    -- Adapters
    dap.adapters.netcoredbg = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/lazy/netcoredbg-macOS-arm64.nvim/netcoredbg/netcoredbg",
      args = { "--interpreter=vscode" },
    }

    dap.adapters.coreclr = require("meon.util.vsdbg").get_adapter()

    -- Python adapter (debugpy)
    local python_adapter = function(cb, config)
      if config.request == "attach" then
        local port = (config.connect or config).port
        local host = (config.connect or config).host or "127.0.0.1"
        cb({ type = "server", port = assert(port, "port required for attach"), host = host })
      else
        cb({
          type = "executable",
          command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
          args = { "-m", "debugpy.adapter" },
        })
      end
    end
    dap.adapters.python = python_adapter
    dap.adapters.debugpy = python_adapter

    -- Go adapter (delve)
    dap.adapters.go = {
      type = "server",
      port = "${port}",
      executable = {
        command = vim.fn.stdpath("data") .. "/mason/packages/delve/dlv",
        args = { "dap", "-l", "127.0.0.1:${port}" },
      },
    }
    dap.adapters.delve = dap.adapters.go

    -- Load configurations from .vscode/launch.json
    local vscode = require("dap.ext.vscode")
    vscode.json_decode = require("meon.util.json5").decode

    -- Type mappings for launch.json
    local type_to_filetypes = {
      python = { "python" },
      debugpy = { "python" },
      go = { "go" },
      delve = { "go" },
    }

    -- Helper to reload launch.json
    local function load_launchjs()
      -- Clear ALL existing configurations from launch.json
      for _, filetypes in pairs(type_to_filetypes) do
        for _, ft in ipairs(filetypes) do
          dap.configurations[ft] = {}
        end
      end
      local launch_path = vim.fn.getcwd() .. "/.vscode/launch.json"
      if vim.fn.filereadable(launch_path) == 1 then
        vscode.load_launchjs(launch_path, type_to_filetypes)
      end
    end

    -- Load on first use of F5, not on startup
    local loaded = false
    local original_continue = dap.continue
    dap.continue = function(...)
      if not loaded then
        load_launchjs()
        loaded = true
      end
      return original_continue(...)
    end

    -- Reload on directory change
    vim.api.nvim_create_autocmd("DirChanged", {
      callback = function()
        loaded = false
      end,
    })

    -- Keymaps
    vim.keymap.set("n", "<F5>", dap.continue)
    vim.keymap.set("n", "<F8>", dap.step_out)
    vim.keymap.set("n", "<F9>", dap.toggle_breakpoint)
    vim.keymap.set("n", "<F10>", dap.step_over)
    vim.keymap.set("n", "<F11>", dap.step_into)
    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dC", dap.clear_breakpoints, { desc = "Clear all breakpoints" })
    vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open DAP REPL" })
    vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate debug session" })
    vim.keymap.set("n", "<leader>de", function()
      local expr = vim.fn.input("Evaluate: ")
      if expr ~= "" then require("dapui").eval(expr, { enter = true }) end
    end, { desc = "Evaluate expression" })
    vim.keymap.set("n", "<leader>fb", function()
      dap.list_breakpoints()
      require("fzf-lua").quickfix()
    end, { desc = "Find breakpoints" })
    vim.keymap.set("n", "<leader>dl", function()
      loaded = false
      load_launchjs()
      loaded = true
      vim.notify("Reloaded launch.json", vim.log.levels.INFO)
    end, { desc = "Reload launch.json" })

    -- Exception breakpoint toggle (global for lualine)
    _G.dap_exception_mode = "off"
    dap.set_exception_breakpoints({})
    vim.keymap.set("n", "<leader>dx", function()
      if _G.dap_exception_mode == "off" then
        _G.dap_exception_mode = "user-unhandled"
        dap.set_exception_breakpoints({ "user-unhandled" })
        vim.notify("Exceptions: user-unhandled", vim.log.levels.INFO)
      elseif _G.dap_exception_mode == "user-unhandled" then
        _G.dap_exception_mode = "all"
        dap.set_exception_breakpoints({ "all" })
        vim.notify("Exceptions: ALL", vim.log.levels.WARN)
      else
        _G.dap_exception_mode = "off"
        dap.set_exception_breakpoints({})
        vim.notify("Exceptions: OFF", vim.log.levels.INFO)
      end
    end, { desc = "Toggle exception breakpoints" })
  end,
}

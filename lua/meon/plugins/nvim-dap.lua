return {
  "mfussenegger/nvim-dap",
  lazy = false,
  dependencies = {
    -- Ships a prebuilt macOS/arm64 netcoredbg; useless (and a failed build) elsewhere.
    { "Cliffback/netcoredbg-macOS-arm64.nvim", enabled = vim.fn.has("mac") == 1 },
  },
  config = function()
    local dap = require("dap")

    -- Adapters
    -- netcoredbg: bundled binary on macOS, Mason's build on Linux, PATH as a
    -- last resort.
    local netcoredbg = vim.fn.stdpath("data") .. "/lazy/netcoredbg-macOS-arm64.nvim/netcoredbg/netcoredbg"
    if vim.fn.executable(netcoredbg) == 0 then
      local mason = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg"
      netcoredbg = vim.fn.executable(mason) == 1 and mason or "netcoredbg"
    end
    dap.adapters.netcoredbg = {
      type = "executable",
      command = netcoredbg,
      args = { "--interpreter=vscode" },
    }

    -- Resolved on first use, not at startup: locating vsdbg touches the
    -- filesystem, and most sessions never start a .NET debug session.
    -- Without the VS Code C# extension (no vsdbg), fall back to netcoredbg.
    dap.adapters.coreclr = function(callback, _)
      local adapter = require("meon.util.vsdbg").get_adapter()
      if adapter then
        callback(adapter)
      elseif vim.fn.executable(netcoredbg) == 1 then
        callback(dap.adapters.netcoredbg)
      else
        vim.notify("No .NET debugger found - install netcoredbg via :MasonInstall netcoredbg", vim.log.levels.ERROR)
      end
    end

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

    -- Configure .vscode/launch.json auto-loading (read on-demand automatically)
    local vscode = require("dap.ext.vscode")
    vscode.json_decode = require("meon.util.json5").decode
    vscode.type_to_filetypes = {
      python = { "python" },
      debugpy = { "python" },
      go = { "go" },
      delve = { "go" },
    }

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
    -- Exception breakpoints (mode is global so lualine can show it).
    -- dap.set_exception_breakpoints() only affects the *running* session, so
    -- new sessions would otherwise get the adapter's own default (vsdbg uses
    -- "user-unhandled", which stops on every exception the ASP.NET pipeline
    -- catches, e.g. a missing file in an endpoint). Instead, the mode is
    -- written into dap.defaults[type] so it applies to every new session too.
    --
    --   unhandled      (default) only exceptions that would crash the process,
    --                  e.g. a startup failure in Program.cs / app entrypoint
    --   user-unhandled exceptions leaving user code, even if a framework catches
    --                  them (endpoint exceptions)
    --   all            every thrown exception
    --
    -- .NET debuggers always break on truly unhandled exceptions, so an empty
    -- filter list there means "unhandled only". debugpy needs "uncaught".
    local exception_filters = {
      ["unhandled"] = { dotnet = {}, python = { "uncaught" } },
      ["user-unhandled"] = { dotnet = { "user-unhandled" }, python = { "userUnhandled" } },
      ["all"] = { dotnet = { "all" }, python = { "raised", "uncaught" } },
    }
    local adapter_family = {
      coreclr = "dotnet",
      netcoredbg = "dotnet",
      python = "python",
      debugpy = "python",
    }
    local exception_modes = { "unhandled", "user-unhandled", "all" }

    local function set_exception_mode(mode)
      _G.dap_exception_mode = mode
      for type, family in pairs(adapter_family) do
        dap.defaults[type].exception_breakpoints = exception_filters[mode][family]
      end
      local session = dap.session()
      local family = session and adapter_family[session.config.type]
      if family then
        session:set_exception_breakpoints(exception_filters[mode][family])
      end
    end
    set_exception_mode("unhandled")

    vim.keymap.set("n", "<leader>dx", function()
      local next_mode = exception_modes[1]
      for i, m in ipairs(exception_modes) do
        if m == _G.dap_exception_mode then
          next_mode = exception_modes[i % #exception_modes + 1]
        end
      end
      set_exception_mode(next_mode)
      vim.notify("Exceptions: " .. next_mode, next_mode == "all" and vim.log.levels.WARN or vim.log.levels.INFO)
    end, { desc = "Cycle exception breakpoints (unhandled/user-unhandled/all)" })
  end,
}

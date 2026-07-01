return {
  "stevearc/overseer.nvim",
  cmd = { "OverseerToggle", "OverseerTaskAction", "LaunchTask" },
  keys = { "<leader>or", "<leader>ot", "<leader>oa" },
  config = function()
    local overseer = require("overseer")
    local json_decode = require("meon.util.json5").decode

    overseer.setup({
      strategy = "terminal",
      templates = { "builtin" },
      task_list = {
        direction = "right",
        default_detail = 2,
      },
    })

    local function get_project_root()
      local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
      if vim.v.shell_error == 0 and git_root and git_root ~= "" then
        return git_root
      end
      return vim.fn.getcwd()
    end

    local function load_launch_json()
      local launch_path = vim.fn.getcwd() .. "/.vscode/launch.json"
      if vim.fn.filereadable(launch_path) == 0 then
        return nil
      end
      local content = table.concat(vim.fn.readfile(launch_path), "\n")
      return json_decode(content)
    end

    local function get_task_spec(config)
      local cwd = get_project_root()

      local function resolve_path(path)
        if not path then return nil end
        return path:gsub("%${workspaceFolder}", cwd):gsub("%${file}", vim.fn.expand("%:p"))
      end

      local function get_runtime(program, config_type)
        if program then
          local ext = program:match("%.([^.]+)$")
          local runtimes = {
            py = { "python" }, js = { "node" }, ts = { "npx", "ts-node" }, rb = { "ruby" },
            pl = { "perl" }, php = { "php" }, lua = { "lua" }, sh = { "bash" },
            dll = { "dotnet" }, go = { "go", "run" },
          }
          if ext and runtimes[ext] then return runtimes[ext] end
        end
        local type_runtimes = {
          go = { "go", "run" }, delve = { "go", "run" },
          python = { "python" }, debugpy = { "python" },
          node = { "node" }, ["pwa-node"] = { "node" },
        }
        return type_runtimes[config_type]
      end

      local cmd = {}

      if config.runtimeExecutable then
        table.insert(cmd, resolve_path(config.runtimeExecutable) or config.runtimeExecutable)
        for _, arg in ipairs(config.runtimeArgs or {}) do table.insert(cmd, arg) end
      elseif config.cargo then
        cmd = { "cargo", "run" }
        for _, arg in ipairs(config.cargo.args or {}) do
          if arg ~= "build" and arg ~= "test" then table.insert(cmd, arg) end
        end
      elseif config.module then
        table.insert(cmd, resolve_path(config.python) or "python")
        table.insert(cmd, "-m")
        table.insert(cmd, config.module)
      elseif config.program then
        local program = resolve_path(config.program) or config.program
        if config.python then
          table.insert(cmd, resolve_path(config.python))
          table.insert(cmd, program)
        else
          local runtime = get_runtime(program, config.type)
          if runtime then
            for _, part in ipairs(runtime) do table.insert(cmd, part) end
            table.insert(cmd, program)
          else
            table.insert(cmd, program)
          end
        end
      elseif config.projectPath then
        cmd = { "dotnet", "run", "--project", resolve_path(config.projectPath) or config.projectPath }
      else
        return nil
      end

      for _, arg in ipairs(config.args or {}) do table.insert(cmd, arg) end

      return {
        name = config.name,
        cmd = cmd,
        cwd = resolve_path(config.cwd) or cwd,
        env = config.env,
      }
    end

    local function has_dap_adapter(config_type)
      local dap = require("dap")
      return dap.adapters[config_type] ~= nil
    end

    local function run_with_overseer(config)
      local spec = get_task_spec(config)
      if spec then
        local task = overseer.new_task(spec)
        task:start()
        return task
      end
      return nil
    end

    local function create_dap_task(name)
      local dap = require("dap")
      local safe = name:gsub("[^%w]", "_")
      local logfile = "/tmp/dap_overseer_" .. safe .. "_" .. os.time() .. ".log"
      vim.fn.writefile({}, logfile)

      local task = overseer.new_task({
        name = name,
        cmd = { "tail", "-f", logfile },
      })
      task:start()

      -- Unique listener id so concurrent tasks don't clobber each other.
      local listener_id = "overseer_" .. safe .. "_" .. os.time()
      local my_session = nil
      local finished = false

      -- Bind this task to the FIRST session whose config name matches, then
      -- match by session id. Without this, every handler fires for every
      -- session and stopping one project cascades into the others.
      local function owns(session)
        if my_session then
          return session.id == my_session.id
        end
        if session.config and session.config.name == name then
          my_session = session
          return true
        end
        return false
      end

      -- Pipe ONLY this session's console output to the log file
      dap.listeners.after.event_output[listener_id] = function(session, body)
        if not owns(session) then return end
        if body.output then
          local f = io.open(logfile, "a")
          if f then
            f:write(body.output)
            f:close()
          end
        end
      end

      -- Cleanup on terminate/exit of THIS session only
      local function cleanup(session)
        if not owns(session) then return end
        finished = true
        dap.listeners.after.event_output[listener_id] = nil
        dap.listeners.after.event_terminated[listener_id] = nil
        dap.listeners.after.event_exited[listener_id] = nil
        task:stop()
        vim.defer_fn(function() os.remove(logfile) end, 1000)
      end

      dap.listeners.after.event_terminated[listener_id] = cleanup
      dap.listeners.after.event_exited[listener_id] = cleanup

      -- Kill ONLY this task's own DAP session when the Overseer task is
      -- disposed. A bare dap.terminate() would kill the focused session,
      -- which is usually a different project.
      task:subscribe("on_dispose", function()
        if my_session and not finished then
          my_session:disconnect({ terminateDebuggee = true })
        end
      end)

      return task
    end

    -- Java debugging needs jdtls to have (a) loaded the java-debug bundle and
    -- (b) finished importing the project, which registers the vscode.java.*
    -- commands. Running before that yields cryptic "No LSP client found" errors,
    -- so gate on it and tell the user to wait.
    local function jdtls_ready()
      for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
        local cmds = (c.server_capabilities.executeCommandProvider or {}).commands or {}
        if vim.tbl_contains(cmds, "vscode.java.startDebugSession") then
          return true
        end
      end
      return false
    end

    local function run_config(config)
      local dap = require("dap")

      if config.type == "java" and not jdtls_ready() then
        vim.notify(
          "jdtls isn't ready yet (open a .java file and let the project finish importing), then try again.",
          vim.log.levels.WARN
        )
        return false
      end

      if has_dap_adapter(config.type) then
        -- Java's debug adapter defaults to console="integratedTerminal", which
        -- launches the debuggee via a runInTerminal reverse-request that often
        -- times out ("Failed to launch debuggee in terminal"). internalConsole
        -- makes the adapter launch the JVM itself and stream stdout/stderr as DAP
        -- output events -- which create_dap_task() already pipes to the panel.
        if config.type == "java" and config.console == nil then
          config.console = "internalConsole"
        end

        create_dap_task(config.name)
        local ok, err = pcall(dap.run, config)
        if not ok then
          vim.notify("dap.run failed: " .. tostring(err), vim.log.levels.ERROR)
          return false
        end
        return true
      else
        local ok = run_with_overseer(config) ~= nil
        if not ok then
          vim.notify(
            ("No DAP adapter for type '%s' and no runnable command built from this config."):format(
              tostring(config.type)
            ),
            vim.log.levels.ERROR
          )
        end
        return ok
      end
    end

    local function run_task(name)
      local json = load_launch_json()
      if not json then
        vim.notify("No launch.json found", vim.log.levels.ERROR)
        return
      end

      for _, config in ipairs(json.configurations or {}) do
        if config.name == name then
          run_config(config)
          overseer.open()
          return
        end
      end

      for _, compound in ipairs(json.compounds or {}) do
        if compound.name == name then
          local configs = {}
          for _, c in ipairs(json.configurations or {}) do
            configs[c.name] = c
          end

          for _, config_name in ipairs(compound.configurations) do
            local config = configs[config_name]
            if config then
              run_config(config)
            else
              vim.notify("Config not found: " .. config_name, vim.log.levels.WARN)
            end
          end
          overseer.open()
          return
        end
      end

      vim.notify("Task not found: " .. name, vim.log.levels.ERROR)
    end

    local function select_and_run()
      local json = load_launch_json()
      if not json then
        vim.notify("No launch.json found", vim.log.levels.ERROR)
        return
      end

      local items = {}

      for _, compound in ipairs(json.compounds or {}) do
        table.insert(items, "[Compound] " .. compound.name)
      end

      for _, config in ipairs(json.configurations or {}) do
        if config.request == "launch" and config.name then
          table.insert(items, config.name)
        end
      end

      vim.ui.select(items, { prompt = "Debug:" }, function(choice)
        if choice then
          local name = choice:gsub("^%[Compound%] ", "")
          run_task(name)
        end
      end)
    end

    vim.api.nvim_create_user_command("LaunchTask", function(opts)
      if opts.args and opts.args ~= "" then
        run_task(opts.args)
      else
        select_and_run()
      end
    end, {
      nargs = "?",
      complete = function()
        local json = load_launch_json()
        if not json then return {} end
        local names = {}
        for _, c in ipairs(json.compounds or {}) do
          table.insert(names, c.name)
        end
        for _, c in ipairs(json.configurations or {}) do
          if c.name then
            table.insert(names, c.name)
          end
        end
        return names
      end,
    })

    local map = vim.keymap.set

    map("n", "<leader>or", select_and_run, { desc = "Debug task" })
    map("n", "<leader>ot", "<Cmd>OverseerToggle<CR>", { desc = "Toggle task list" })
    map("n", "<leader>oa", "<Cmd>OverseerTaskAction<CR>", { desc = "Task action" })
  end,
}

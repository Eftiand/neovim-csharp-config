vim.g.mapleader = " "

-- Load user settings from settings.json
local settings_path = vim.fn.stdpath("config") .. "/settings.json"
local function load_settings()
  local f = io.open(settings_path, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  return ok and data or {}
end

local function save_settings(tbl)
  local f = io.open(settings_path, "w")
  if not f then return end
  f:write(vim.json.encode(tbl))
  f:close()
end

local settings = load_settings()
vim.g.ai_assistant = settings.ai_assistant or "claude"

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- AI assistant toggle (<leader><space> opens active, <leader>as switches)
keymap.set({ "n", "v" }, "<leader><space>", function()
  if vim.g.ai_assistant == "opencode" then
    require("opencode").toggle()
  else
    vim.cmd("ClaudeCode")
  end
end, { desc = "Toggle AI assistant" })

keymap.set("n", "<leader>as", function()
  vim.g.ai_assistant = vim.g.ai_assistant == "claude" and "opencode" or "claude"
  local s = load_settings()
  s.ai_assistant = vim.g.ai_assistant
  save_settings(s)
  vim.notify("AI assistant: " .. vim.g.ai_assistant, vim.log.levels.INFO)
end, { desc = "Switch AI assistant (claude/opencode)" })

-- Reload config
keymap.set("n", "<leader>rr", "<cmd>source ~/.config/nvim/init.lua<CR>", { desc = "Reload Neovim config" })

-- window management
keymap.set("n", "sh", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "sv", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>ta", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Terminal keymaps (using 'ft' prefix for 'floating terminal')
keymap.set("n", "<leader>tt", "<cmd>terminal<CR>", { desc = "Open terminal in new buffer" })
keymap.set("n", "<leader>th", "<cmd>split | terminal<CR>", { desc = "Open terminal in horizontal split" })
keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<CR>", { desc = "Open terminal in vertical split" })

-- Terminal window navigation (works in all terminal buffers except fzf-lua)
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.defer_fn(function()
      if vim.bo.filetype == "fzf" then return end

      local opts = { buffer = 0, silent = true }
      vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
      vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
      vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
      vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
    end, 10)
  end,
})

-- Build
keymap.set("n", "<leader>bp", function()
  local tasks_path = vim.fn.getcwd() .. "/.vscode/tasks.json"
  local cmd = nil

  -- Try to read default build task from .vscode/tasks.json
  if vim.fn.filereadable(tasks_path) == 1 then
    local content = table.concat(vim.fn.readfile(tasks_path), "\n")
    content = content:gsub("//.-\n", "\n"):gsub("/%*.-%*/", "")
    local ok, json = pcall(vim.json.decode, content)
    if ok and json and json.tasks then
      for _, task in ipairs(json.tasks) do
        local group = task.group
        if type(group) == "table" and group.kind == "build" and group.isDefault then
          local command = task.command or ""
          local args = task.args or {}
          -- Replace ${workspaceFolder} with cwd
          local cwd = vim.fn.getcwd()
          for i, arg in ipairs(args) do
            args[i] = arg:gsub("%${workspaceFolder}", cwd)
          end
          cmd = command .. " " .. table.concat(args, " ")
          break
        end
      end
    end
  end

  -- Fallback: find .sln or .slnx in cwd
  if not cmd then
    local files = vim.fn.glob("*.sln", false, true)
    vim.list_extend(files, vim.fn.glob("*.slnx", false, true))
    cmd = #files > 0 and ("dotnet build " .. files[1]) or "dotnet build"
  end

  local output = {}
  local start_time = vim.uv.hrtime()

  -- Update lualine build status
  _G.build_status = _G.build_status or {}
  _G.build_status.running = true
  _G.build_status.message = ""
  _G.build_status.level = "info"
  vim.cmd("redrawstatus")

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then vim.list_extend(output, data) end
    end,
    on_stderr = function(_, data)
      if data then vim.list_extend(output, data) end
    end,
    on_exit = function(_, code)
      local elapsed = (vim.uv.hrtime() - start_time) / 1e9
      vim.schedule(function()
        -- Parse dotnet build output: path/file.cs(line,col): error CS1234: message
        vim.fn.setqflist({}, " ", {
          title = "dotnet build",
          lines = output,
          efm = "%f(%l\\,%c): %trror %m,%-G%.%#",
        })

        _G.build_status.running = false
        if code == 0 then
          _G.build_status.message = string.format("✓ Build succeeded (%.1fs)", elapsed)
          _G.build_status.level = "ok"
        else
          _G.build_status.message = string.format("✗ Build failed (%.1fs)", elapsed)
          _G.build_status.level = "error"
          vim.cmd("copen")
        end
        vim.cmd("redrawstatus")

        -- Clear message after 5 seconds
        vim.defer_fn(function()
          if not _G.build_status.running then
            _G.build_status.message = ""
            vim.cmd("redrawstatus")
          end
        end, 5000)
      end)
    end,
  })
end, { desc = "Build project" })

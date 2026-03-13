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

-- AI assistant toggle (<leader><Esc> opens active, <leader>as switches)
local function toggle_ai()
  if vim.g.ai_assistant == "opencode" then
    require("opencode").toggle()
  else
    vim.cmd("ClaudeCode")
  end
end
keymap.set({ "n", "v" }, "<leader><Esc>", toggle_ai, { desc = "Toggle AI assistant" })
keymap.set({ "n", "v" }, "<leader><space>", toggle_ai, { desc = "Toggle AI assistant" })

keymap.set("x", "<leader>i", function()
  if vim.g.ai_assistant == "opencode" then
    return require("opencode").operator("@this ")
  else
    vim.cmd("ClaudeCodeSend")
    vim.schedule(function()
      vim.cmd("ClaudeCodeFocus")
    end)
    return ""
  end
end, { expr = true, desc = "Send selection to AI assistant" })

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

-- JSON: convert class/object properties to JSON object (visual selection, language-agnostic)
local modifiers = {
  "public", "private", "protected", "internal", "static", "virtual", "abstract",
  "override", "readonly", "sealed", "extern", "new", "val", "var", "let", "const",
  "def", "final", "open", "suspend", "inline", "required", "optional", "lateinit",
}

local skip_patterns = { "^{", "^}", "class%s", "interface%s", "struct%s", "enum%s", "record%s" }

local function extract_prop_name(line)
  line = line:match("^%s*(.-)%s*$")
  if line == "" then return nil end
  for _, pat in ipairs(skip_patterns) do
    if line:match(pat) then return nil end
  end

  -- Strip trailing block/getter syntax and semicolons
  line = line:gsub("{%s*get.*", ""):gsub("{%s*set.*", ""):gsub(";.*", ""):gsub("{.*", "")
  -- Strip trailing punctuation (commas, colons after type, etc.)
  line = line:match("^%s*(.-)%s*$")

  -- Strip leading access modifiers
  local changed = true
  while changed do
    changed = false
    for _, mod in ipairs(modifiers) do
      local stripped = line:match("^" .. mod .. "%s+(.*)")
      if stripped then line = stripped; changed = true end
    end
  end
  line = line:match("^%s*(.-)%s*$")

  -- name: Type  (TypeScript, Python, Kotlin, Rust)
  local name = line:match("^([%a_][%w_]*)%s*:")
  if name then return name end

  -- Type name  (C#, Java, Go — two tokens, name is last)
  name = line:match("^[%a_][%w_.<>%[%]%?%*,%%]+%s+([%a_][%w_]*)%s*$")
  if name then return name end

  -- name = ...  (assignments)
  name = line:match("^([%a_][%w_]*)%s*[=%(]")
  if name then return name end

  -- bare single identifier
  name = line:match("^([%a_][%w_]*)%s*$")
  return name
end

local function class_to_json()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local props = {}
  for _, line in ipairs(lines) do
    local name = extract_prop_name(line)
    if name then
      table.insert(props, string.format('  "%s": null', name))
    end
  end

  if #props == 0 then
    vim.notify("No properties found in selection", vim.log.levels.WARN)
    return
  end

  local result = { "{" }
  for i, p in ipairs(props) do
    table.insert(result, p .. (i < #props and "," or ""))
  end
  table.insert(result, "}")

  vim.cmd("vnew")
  vim.bo.buftype = "nofile"
  vim.bo.filetype = "json"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, result)
end

keymap.set("v", "<leader>jo", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  class_to_json()
end, { desc = "Convert class properties to JSON" })



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

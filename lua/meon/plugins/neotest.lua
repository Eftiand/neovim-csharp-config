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
      -- Two upstream gaps, re-applied after every install/update (each
      -- substitution is idempotent):
      --  1. Neovim 0.11+ returns treesitter capture values as lists of nodes,
      --     not single nodes, which breaks framework detection and
      --     parameterized test discovery.
      --  2. neotest parses positions in a child Neovim run with `-u NONE`, so
      --     nvim-treesitter never loads there and the `cs` -> `c_sharp` parser
      --     alias is missing, making every parse fail with
      --     `No parser for language "cs"`.
      build = function(plugin)
        local patches = {
          ["lua/neotest-dotnet/framework-discovery.lua"] = {
            {
              [[    local test_attribute = vim.fn.has("nvim-0.9.0") == 1
        and vim.treesitter.get_node_text(captures[1], source)
      or vim.treesitter.query.get_node_text(captures[1], source)]],
              [[    local capture = captures[1]
    if type(capture) == "table" then
      capture = capture[1]
    end
    local test_attribute = capture
      and (
        vim.fn.has("nvim-0.9.0") == 1 and vim.treesitter.get_node_text(capture, source)
        or vim.treesitter.query.get_node_text(capture, source)
      )]],
            },
          },
          ["lua/neotest-dotnet/init.lua"] = {
            {
              [[local build_spec_utils = require("neotest-dotnet.utils.build-spec-utils")
]],
              [[local build_spec_utils = require("neotest-dotnet.utils.build-spec-utils")

-- Neovim core does not map the `cs` filetype to the `c_sharp` parser; that alias
-- normally comes from nvim-treesitter. neotest parses positions in a child
-- Neovim started with `-u NONE`, where no plugins load, so the alias must be
-- registered here (this module is required in the child before parsing).
--
-- It has to be deferred. The child first requires this module while evaluating
-- the `build_position` string inside an RPC handler, which is a fast event
-- context. Loading `vim.treesitter` there creates an augroup and raises
-- E5560, and Lua then leaves `neotest-dotnet` permanently poisoned in that
-- child ("loop or previous error loading module"), so every file parses to
-- zero positions. `pcall(vim.treesitter.language.register, ...)` does not
-- protect against this: the index expression is evaluated before pcall runs.
vim.schedule(function()
  pcall(function()
    vim.treesitter.language.register("c_sharp", "cs")
  end)
end)
]],
            },
          },
          ["lua/neotest-dotnet/utils/build-spec-utils.lua"] = {
            {
              [[  return #specs < 0 and nil or specs]],
              [[  -- Upstream typo: `< 0` is never true, so "no specs" came back as an empty
  -- table. neotest treats that as a single spec (`{ {} }`), runs it, and then
  -- crashes in `results` indexing `spec.context`. Returning nil is the
  -- documented "cannot run this position" signal.
  return #specs == 0 and nil or specs]],
            },
          },
          ["lua/neotest-dotnet/nunit/init.lua"] = {
            {
              [[    local args_node = match[arguments_index]
]],
              [[    local args_node = match[arguments_index]
    if type(args_node) == "table" then
      args_node = args_node[1]
    end
]],
            },
          },
          ["lua/neotest-dotnet/mstest/init.lua"] = {
            {
              [[    local args_node = match[arguments_index]
]],
              [[    local args_node = match[arguments_index]
    if type(args_node) == "table" then
      args_node = args_node[1]
    end
]],
            },
          },
        }

        for file, replacements in pairs(patches) do
          local path = plugin.dir .. "/" .. file
          local f = io.open(path, "r")
          if f then
            local content = f:read("*a")
            f:close()
            local changed = false
            for _, pair in ipairs(replacements) do
              local old, new = pair[1], pair[2]
              if not content:find(new, 1, true) and content:find(old, 1, true) then
                content = content:gsub(vim.pesc(old), (new:gsub("%%", "%%%%")), 1)
                changed = true
              end
            end
            if changed then
              local w = io.open(path, "w")
              if w then
                w:write(content)
                w:close()
              end
            end
          end
        end
      end,
    },
  },
  config = function()
    require("neotest").setup({
      -- DEBUG logs every file read during discovery; it had grown a 197MB
      -- neotest.log and put a synchronous write in the discovery hot path.
      log_level = vim.log.levels.WARN,
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

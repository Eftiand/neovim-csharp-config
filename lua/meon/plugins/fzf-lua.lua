return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	lazy = false,
	config = function()
		local fzf = require("fzf-lua")

		fzf.setup({
			-- Use fzf-native for better performance
			winopts = {
				height = 0.85,
				width = 0.80,
				row = 0.35,
				col = 0.50,
				preview = {
					scrollbar = "float",
				},
			},
			fzf_opts = {
				-- Enable fzf's built-in debouncing
				["--layout"] = "default",
				["--info"] = "inline",
				["-i"] = "", -- Case-insensitive search
			},
			-- Performance optimizations
			files = {
				prompt = "Files❯ ",
				cmd = "fd --type f --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude build --exclude dist --exclude target --exclude .next --exclude .cache",
				git_icons = false, -- Disable git icons for speed
				file_icons = true,
				color_icons = true,
				fzf_opts = { ["--exact"] = "" }, -- Exact substring matching instead of fuzzy
			},
			grep = {
				prompt = "Grep❯ ",
				input_debounce = 200, -- 200ms debounce for live grep
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/' --glob '!node_modules/' --glob '!build/' --glob '!dist/'",
				git_icons = false,
				file_icons = true,
			},
			oldfiles = {
				prompt = "Recent❯ ",
				cwd_only = true,
				include_current_session = true,
				git_icons = false,
				file_icons = true,
			},
		})

		-- Register as vim.ui.select handler
		fzf.register_ui_select()

		-- Set keymaps
		local keymap = vim.keymap

		keymap.set("n", "<leader>ff", function()
			fzf.files()
		end, { desc = "Fuzzy find files in cwd" })

		keymap.set("n", "<leader>fa", function()
			fzf.files({ cmd = "fd --type f --hidden --no-ignore --strip-cwd-prefix --exclude .git" })
		end, { desc = "Fuzzy find all files" })

		keymap.set("n", "<leader>fr", function()
			fzf.oldfiles()
		end, { desc = "Fuzzy find recent files" })

		keymap.set("n", "<leader>fs", function()
			fzf.live_grep()
		end, { desc = "Find string in cwd" })

		keymap.set("n", "<leader>fc", function()
			fzf.grep_cword()
		end, { desc = "Find string under cursor in cwd" })

		keymap.set("n", "<leader>ft", function()
			fzf.grep({ search = "TODO|HACK|PERF|NOTE|FIX", no_esc = true })
		end, { desc = "Find todos" })

		-- <CR> cd into worktree, <C-a> add (from query), <C-x> remove
		keymap.set("n", "<leader>gw", function()
			fzf.git_worktrees()
		end, { desc = "Git worktrees (switch/add/remove)" })
	end,
}

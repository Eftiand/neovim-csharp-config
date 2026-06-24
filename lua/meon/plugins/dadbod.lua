return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	keys = {
		{ "<leader>sq", "<Cmd>DBUIToggle<CR>", desc = "Toggle DB UI" },
		{ "<leader>sf", "<Cmd>DBUIFindBuffer<CR>", desc = "Find DB buffer" },
		{ "<leader>sa", "<Cmd>DBUIAddConnection<CR>", desc = "Add DB connection" },
		{ "<leader>sl", "<Cmd>DBUILastQueryInfo<CR>", desc = "Last query info" },
		{
			"<leader>sj",
			function()
				-- Get the full line content
				local content = vim.api.nvim_get_current_line()

				-- Try to find JSON object/array in the content
				local json_start = content:find("[{%[]")
				if json_start then
					content = content:sub(json_start)
					-- Try to find matching end bracket
					local depth = 0
					local in_string = false
					local escape = false
					local end_pos = nil
					local start_char = content:sub(1, 1)
					local end_char = start_char == "{" and "}" or "]"

					for i = 1, #content do
						local c = content:sub(i, i)
						if escape then
							escape = false
						elseif c == "\\" then
							escape = true
						elseif c == '"' then
							in_string = not in_string
						elseif not in_string then
							if c == "{" or c == "[" then
								depth = depth + 1
							elseif c == "}" or c == "]" then
								depth = depth - 1
								if depth == 0 then
									end_pos = i
									break
								end
							end
						end
					end

					if end_pos then
						content = content:sub(1, end_pos)
					end
				end

				-- Open in vertical split
				vim.cmd("vnew")
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "wipe"
				vim.bo.filetype = "json"

				-- Insert content
				vim.api.nvim_buf_set_lines(0, 0, -1, false, { content })

				-- Try to format with jq if available
				if vim.fn.executable("jq") == 1 then
					vim.cmd("silent! %!jq .")
				end
			end,
			desc = "Open JSON in buffer",
			ft = "dbout",
		},
	},
	init = function()
		-- Use nerd fonts icons
		vim.g.db_ui_use_nerd_fonts = 1

		-- Save queries location
		vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"

		-- Disable execute on save
		vim.g.db_ui_execute_on_save = 0

		-- Connections are added dynamically via DBUIAddConnection
		-- They persist in vim.g.db_ui_save_location
		vim.g.dbs = {}
	end,
	config = function()
		-- Setup completion for sql files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "sql", "mysql", "plsql" },
			callback = function()
				require("cmp").setup.buffer({
					sources = {
						{ name = "vim-dadbod-completion" },
						{ name = "buffer" },
					},
				})

				-- Execute query (avoids <leader>S clash with snacks scratch)
				vim.keymap.set("n", "<leader>sr", "<Plug>(DBUI_ExecuteQuery)", {
					buffer = true,
					desc = "Run DB query",
				})
				vim.keymap.set("v", "<leader>sr", "<Plug>(DBUI_ExecuteQuery)", {
					buffer = true,
					desc = "Run DB query (selection)",
				})
			end,
		})
	end,
}

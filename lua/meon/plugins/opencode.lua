return {
	"nickjvandyke/opencode.nvim",
	version = "*",
	dependencies = {
		{
			"folke/snacks.nvim",
			optional = true,
			opts = {
				input = {},
				picker = {
					actions = {
						opencode_send = function(...) return require('opencode').snacks_picker_send(...) end,
					},
					win = {
						input = {
							keys = {
								['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
							},
						},
					},
				},
				terminal = {},
			},
		},
	},
	config = function()
		---@type opencode.Opts
		vim.g.opencode_opts = {
			provider = {
				snacks = {
					win = {
						position = "left",
						width = 0.33,
					}, },
			},
		}

		vim.o.autoread = true

		-- keymaps
		vim.keymap.set({ "n", "x" }, "<c-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "ask opencode…" })
		vim.keymap.set({ "n", "x" }, "<c-x>", function() require("opencode").select() end, { desc = "execute opencode action…" })
		vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

		vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Add range to opencode", expr = true })
		vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

		vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end, { desc = "Scroll opencode up" })
		vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })

		-- Remap increment/decrement since <C-a> and <C-x> are taken
		vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
		vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })

		-- Kill opencode process when neovim exits
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				for _, chan in pairs(vim.api.nvim_list_chans()) do
					if chan.mode == "terminal" and chan.pty then
						local bufname = vim.api.nvim_buf_get_name(chan.buffer or 0)
						if bufname:find("opencode") then
							pcall(vim.fn.jobstop, chan.id)
						end
					end
				end
			end,
		})

		-- Tmux navigation in opencode terminal
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "opencode_terminal",
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
				vim.keymap.set("t", "<C-h>", [[<C-\><C-n><cmd>TmuxNavigateLeft<cr>]], opts)
				vim.keymap.set("t", "<C-j>", [[<C-\><C-n><cmd>TmuxNavigateDown<cr>]], opts)
				vim.keymap.set("t", "<C-k>", [[<C-\><C-n><cmd>TmuxNavigateUp<cr>]], opts)
				vim.keymap.set("t", "<C-l>", [[<C-\><C-n><cmd>TmuxNavigateRight<cr>]], opts)
			end,
		})
	end,
}

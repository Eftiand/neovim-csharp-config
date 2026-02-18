return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	event = "VeryLazy",
	config = function(_, opts)
		require("claudecode").setup(opts)

		-- Close terminal buffers on quit so :qa works cleanly
		vim.api.nvim_create_autocmd("QuitPre", {
			callback = function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end
			end,
		})

	end,
	keys = {
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{
			"<C-i>",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
		},
		-- Diff management
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
	opts = {
		terminal_cmd = "bash -c 'claude --dangerously-skip-permissions --continue 2>/dev/null || claude --dangerously-skip-permissions'",
		terminal = {
			provider = "snacks",
			snacks_win_opts = {
				position = "left",
				width = 0.33,
				height = 0.6,
				border = "double",
				backdrop = 80,
				wo = {
					winblend = 0,
					winhighlight = "Normal:ClaudeCodeBackground,NormalFloat:ClaudeCodeBackground",
				},
			},
		},
	},
}

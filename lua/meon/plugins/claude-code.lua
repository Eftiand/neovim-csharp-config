return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	config = function(_, opts)
		require("claudecode").setup(opts)

		-- Custom function to send and focus
		vim.keymap.set("v", "<leader>i", function()
			vim.cmd("ClaudeCodeSend")
			vim.schedule(function()
				vim.cmd("ClaudeCodeFocus")
			end)
		end, { desc = "Send to Claude and focus" })
	end,
	keys = {
		{ "<leader><Esc>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude", mode = { "n", "v" } },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{
			"<C-i>",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
		},
		-- Diff management
		{ "<leader>i", "<cmd>ClaudeCodeSend<cr><cmd>ClaudeCodeFocus<cr>", desc = "Send to Claude", mode = "v" },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
	opts = {
		terminal_cmd = "claude --dangerously-skip-permissions",
		terminal = {
			provider = "snacks",
			snacks_win_opts = {
				position = "left",
				width = 0.23,
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

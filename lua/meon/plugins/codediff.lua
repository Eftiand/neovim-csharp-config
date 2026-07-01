return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gv", "<cmd>CodeDiff<cr>", desc = "CodeDiff open" },
	},
	opts = {
		keymaps = {
			view = {
				next_hunk = "n",
				prev_hunk = "p",
				next_file = "N",
				prev_file = "P",
			},
		},
	},
}

return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gv", "<cmd>CodeDiff origin/main...<cr>", desc = "CodeDiff vs origin/main (PR diff)" },
		{ "<leader>gV", "<cmd>CodeDiff<cr>", desc = "CodeDiff working tree" },
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

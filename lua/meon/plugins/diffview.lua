return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
		{ "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
	},
	opts = {},
}

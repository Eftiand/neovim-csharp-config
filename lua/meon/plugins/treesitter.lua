local ensure_installed = {
	"lua",
	"xml",
	"html",
	"css",
	"vim",
	"vimdoc",
	"dockerfile",
	"gitignore",
	"query",
	"c_sharp",
	"python",
	"json",
	"javascript",
	"typescript",
	"tsx",
	"yaml",
	"markdown",
	"markdown_inline",
	"go",
	"gomod",
	"gosum",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = ensure_installed,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = true,
			},
		},
	},
}

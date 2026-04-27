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
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install(ensure_installed)

			local highlight_filetypes = vim.iter(ensure_installed)
				:map(function(lang)
					return vim.treesitter.language.get_filetypes(lang)
				end)
				:flatten()
				:totable()

			vim.api.nvim_create_autocmd("FileType", {
				pattern = highlight_filetypes,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
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

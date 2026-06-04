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

local highlight_filetypes = {
	"lua",
	"xml",
	"html",
	"css",
	"vim",
	"help",
	"dockerfile",
	"gitignore",
	"query",
	"cs",
	"python",
	"json",
	"javascript",
	"javascriptreact",
	"typescript",
	"typescriptreact",
	"yaml",
	"markdown",
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
			local ts = require("nvim-treesitter")
			ts.setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			local installed = ts.get_installed and ts.get_installed("parsers") or {}
			local installed_set = {}
			for _, p in ipairs(installed) do
				installed_set[p] = true
			end
			local missing = {}
			for _, p in ipairs(ensure_installed) do
				if not installed_set[p] then
					table.insert(missing, p)
				end
			end
			if #missing > 0 then
				ts.install(missing)
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = highlight_filetypes,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
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

return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		-- import comment plugin safely
		local comment = require("Comment")
		local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

		-- disable legacy CursorHold autocmd; pre_hook updates commentstring instead.
		-- avoids "attempt to index local 'language_tree' (a nil value)" on buffers w/o a TS parser.
		vim.g.skip_ts_context_commentstring_module = true
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})
		-- enable comment
		comment.setup({
			-- for commenting tsx, jsx, svelte, html files
			pre_hook = ts_context_commentstring.create_pre_hook(),

			-- Additional configuration for C# and HTML
			ft = {
				html = {
					__default = "<!-- %s -->",
				},
			},
		})
	end,
}

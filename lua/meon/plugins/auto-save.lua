return {
	"okuuva/auto-save.nvim",
	event = { "InsertLeave", "TextChanged" },
	opts = {
		enabled = true,
		trigger_events = {
			immediate_save = { "BufLeave", "FocusLost" },
			-- TextChanged removed: it fires on every normal-mode edit (dd, p,
			-- undo) and turned each typing pause into a full write cascade
			-- (backup file + swap sync + conform + LSP didSave + lint).
			defer_save = { "InsertLeave" },
			cancel_deferred_save = { "InsertEnter" },
		},
		condition = function(buf)
			if vim.bo[buf].filetype == "harpoon" then
				return false
			end
			return vim.bo[buf].modifiable
		end,
		write_all_buffers = false,
		debounce_delay = 1500,
		debug = false,
	},
}

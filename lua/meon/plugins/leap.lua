return {
	{
		url = "https://codeberg.org/andyg/leap.nvim",
		keys = { "f", "F" },
		config = function()
			local leap = require("leap")
			vim.keymap.set("n", "f", function()
				leap.leap({ target_windows = vim.tbl_filter(function(win)
					return vim.api.nvim_win_get_config(win).focusable
				end, vim.api.nvim_tabpage_list_wins(0)) })
			end, { desc = "Leap forward" })
			vim.keymap.set("n", "F", function()
				leap.leap({ backward = true, target_windows = vim.tbl_filter(function(win)
					return vim.api.nvim_win_get_config(win).focusable
				end, vim.api.nvim_tabpage_list_wins(0)) })
			end, { desc = "Leap backward" })
		end,
	},
}

return {
	"Eftiand/stocks-watchlist.nvim",
	cmd = "StocksWatchlist",
	keys = {
		{ "<leader>wl", "<cmd>StocksWatchlist<cr>", desc = "Toggle watchlist" },
	},
	opts = {
		watchlist_refresh = .5,
	},
}

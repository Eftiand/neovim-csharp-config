return {
	"nickjvandyke/opencode.nvim",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("opencode").setup()
	end,
}

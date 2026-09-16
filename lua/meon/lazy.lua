local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "meon.plugins" }, { import = "meon.plugins.lsp" } }, {
	checker = {
		enabled = true,
		notify = false,
		-- Default is hourly, which spawns a `git fetch` for every one of the
		-- ~77 plugins and stutters the editor mid-session. Once a day is plenty.
		frequency = 86400,
	},
	performance = {
		rtp = {
			disabled_plugins = { "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor" },
		},
	},
})
